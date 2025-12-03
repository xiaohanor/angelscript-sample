struct FPigStretchLegsFlipCapabilityDeactivationParams
{
	bool bTeleportWasApplied = false;
}

class UPigStretchyLegsFlipCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"Stretch");

	default TickGroup = EHazeTickGroup::ActionMovement;
	default DebugCategory = PigTags::Pig;
	default TickGroupOrder = 39; // Tick before player pig jump

	UPlayerPigComponent PigComponent;
	UPlayerPigStretchyLegsComponent StretchyLegsComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;
	UPlayerAirMotionComponent AirMotionComponent;

	bool bImpulseDelivered;

	float Impulse;

	bool bLocomotionRequested;
	bool bPlayerTeleported;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigComponent = UPlayerPigComponent::Get(Owner);
		StretchyLegsComponent = UPlayerPigStretchyLegsComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		AirMotionComponent = UPlayerAirMotionComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!StretchyLegsComponent.bShouldFlip)
			return false;

		if (IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPigStretchLegsFlipCapabilityDeactivationParams& DeactivationParams) const
	{
		if (ActiveDuration < Pig::StretchyLegs::FlipDuration)
			return false;

		if (MovementComponent.HasGroundContact())
		{
			DeactivationParams.bTeleportWasApplied = bPlayerTeleported;
			return true;
		}

		if (MovementComponent.HasCeilingContact())
		{
			DeactivationParams.bTeleportWasApplied = bPlayerTeleported;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Impulse = StretchyLegsComponent.bWasGrounded ? Pig::StretchyLegs::FlipImpulseGrounded : Pig::StretchyLegs::FlipImpulseAirborne;

		StretchyLegsComponent.bAirborneAfterStretching = true;
		StretchyLegsComponent.ClearSpringyMesh();

		// Consume flip
		StretchyLegsComponent.bShouldFlip = false;
		StretchyLegsComponent.bWasGrounded = false;

		// Apply horizontal only, wait for delay to apply vertical impulse
		FVector HorizontalVelocity = Player.ActorForwardVector * AirMotionComponent.Settings.HorizontalMoveSpeed * MovementComponent.MovementInput.Size();
		Player.SetActorHorizontalVelocity(HorizontalVelocity);

		Player.PlayForceFeedback(StretchyLegsComponent.FlipForceFeedback, false, true, this);

		bImpulseDelivered = false;
		bLocomotionRequested = false;
		bPlayerTeleported = false;

		UStretchyPigEffectEventHandler::Trigger_OnStretchJump(Player);

		Player.BlockCapabilities(PigTags::SpecialAbility, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPigStretchLegsFlipCapabilityDeactivationParams DeactivationParams)
	{
		// Make sure the remote side has done the teleport if the capability got quieted in some way
		if (!bPlayerTeleported && DeactivationParams.bTeleportWasApplied)
			TeleportAndClearCameraSettings();

		StretchyLegsComponent.bAirborneAfterStretching = false;

		Player.UnblockCapabilities(PigTags::SpecialAbility, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			// Slap dat booty
			if (!bImpulseDelivered && ActiveDuration >= Pig::StretchyLegs::AirDelay)
			{
				// Set initial impulse and kick that cam
				
				FHazeTraceSettings Trace = Trace::InitFromMovementComponent(MovementComponent);
				Trace.IgnorePlayers();
				Trace.SetTraceComplex(true);
				FHitResult HitResult = Trace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation + Player.MovementWorldUp * 50.0);
				if (!HitResult.bBlockingHit)
				{
					Player.SetActorVerticalVelocity(Player.MovementWorldUp * Impulse);
					Player.PlayCameraShake(StretchyLegsComponent.FlipCameraShake, this);
				}

				bImpulseDelivered = true;
			}
		}

		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				MoveData.BlockStepDownForThisFrame();

				FVector AirControlVelocity = AirMotionComponent.CalculateStandardAirControlVelocity(MovementComponent.MovementInput, MovementComponent.HorizontalVelocity, DeltaTime);
				MoveData.AddHorizontalVelocity(AirControlVelocity);
				MoveData.AddOwnerVerticalVelocity();

				MoveData.AddGravityAcceleration();

				float InterpSpeed = UPlayerJumpSettings::GetSettings(Player).FacingDirectionInterpSpeed * MovementComponent.MovementInput.Size();
				MoveData.InterpRotationToTargetFacingRotation(InterpSpeed);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			if (Player.Mesh.CanRequestLocomotion())
			{
				Player.RequestLocomotion(n"AirMovement", this);
				bLocomotionRequested = true;
			}

			// Tick flip
			float FlipAlpha = Math::Saturate(ActiveDuration / Pig::StretchyLegs::FlipDuration);

			// float Angle = 360.0 * Math::Pow(FlipAlpha, 1.5);
			// FQuat Rotation = FQuat::MakeFromEuler(FVector(0.0, -Angle, 0.0));
			// Player.MeshOffsetComponent.SetRelativeRotation(Rotation);

			// Teleport player and fix camera after animation has ticked once
			if (bLocomotionRequested && !bPlayerTeleported && ActiveDuration > 0.0)
				TeleportAndClearCameraSettings();
		}
	}

	void TeleportAndClearCameraSettings()
	{
		bPlayerTeleported = true;

		float Height = Pig::StretchyLegs::MaxLength + 60.0;
		Player.TeleportActor(Player.ActorLocation + Player.MovementWorldUp * Height, Player.ActorRotation, this, false);

		// Clear cam stuff that wasn't cleared in stretchy capability
		UCameraSettings CameraSettings = UCameraSettings::GetSettings(Player);
		Player.ClearCameraSettingsByInstigator(StretchyLegsComponent, Pig::StretchyLegs::ClearBlendCameraSettingsDuration);

		// Snap offset back to normal (camera will teleport above player, so...)
		CameraSettings.PivotOffset.Clear(StretchyLegsComponent, 0.0);

		// Snap camera above player with the offset that comes from exit animation (total is 660)
		CameraSettings.PivotOffset.Apply(-FVector::UpVector * 60.0, StretchyLegsComponent, 0.0, EHazeCameraPriority::High);

		// Now hacky af start blending back from offset to new player height
		CameraSettings.PivotOffset.Clear(StretchyLegsComponent, 0.5);
	}
}