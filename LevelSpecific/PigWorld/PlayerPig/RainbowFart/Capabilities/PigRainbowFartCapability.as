struct FPigRainbowFartCapabilityDeactivationParams
{
	bool bFartInterrupted = false;
}

class UPigRainbowFartCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PigTags::SpecialAbility);
	default CapabilityTags.Add(n"Fart");

	// Must tick before jump to avoid farty bunny-hopping
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;

	default DebugCategory = PigTags::Pig;

	UPlayerPigComponent PigComponent;
	UPlayerPigRainbowFartComponent RainbowFartComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;
	UPlayerAirMotionComponent AirMotionComponent;

	UPigMovementSettings Settings;
	URainbowFartPigSettings FartSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigComponent = UPlayerPigComponent::Get(Owner);
		RainbowFartComponent = UPlayerPigRainbowFartComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
		AirMotionComponent = UPlayerAirMotionComponent::Get(Owner);

		Settings = UPigMovementSettings::GetSettings(Player);
		FartSettings = URainbowFartPigSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (!RainbowFartComponent.CanFart())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPigRainbowFartCapabilityDeactivationParams& DeactivationParams) const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
		{
			DeactivationParams.bFartInterrupted = true;
			return true;
		}

		if (RainbowFartComponent.bFartInterrupted)
		{
			DeactivationParams.bFartInterrupted = true;
			return true;
		}

		if (MovementComponent.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RainbowFartComponent.bFarting = true;
		RainbowFartComponent.Activate();
		RainbowFartComponent.bFartInterrupted = false;

		// Movement stuff
		Player.ApplySettings(RainbowFartComponent.GravitySettings, this);
		Player.ApplySettings(RainbowFartComponent.AirMotionSettings, this);

		SetInitialVelocity();

		// Do camera stuff
		Player.ApplyCameraSettings(RainbowFartComponent.SpringArmSettings, 0.5, this, EHazeCameraPriority::High);
		Player.PlayCameraShake(RainbowFartComponent.CameraShakeClass, this, 1.0);
		SpeedEffect::RequestSpeedEffect(Player, 0.5, this, EInstigatePriority::High);
		Player.ApplyCameraImpulse(RainbowFartComponent.CameraImpulse, this);

		// Fire away!
		UPigRainbowFartEffectEventHandler::Trigger_OnFartingStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FPigRainbowFartCapabilityDeactivationParams DeactivationParams)
	{
		RainbowFartComponent.bFarting = false;

		if (!RainbowFartComponent.bFartInterrupted)
			Player.SetActorVelocity(Player.ActorVelocity * 0.5); // Easy there cowboy

		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.2);

		Player.ClearSettingsByInstigator(this);

		Player.ClearCameraSettingsByInstigator(this);
		Player.StopCameraShakeByInstigator(this);

		SpeedEffect::ClearSpeedEffect(Player, this);
		UPigRainbowFartEffectEventHandler::Trigger_OnFartingStopped(Player);

		if (DeactivationParams.bFartInterrupted)
			UPigRainbowFartEffectEventHandler::Trigger_OnFartInterrupted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector AirControlVelocity = AirMotionComponent.CalculateStandardAirControlVelocity(Player.ActorForwardVector, MovementComponent.HorizontalVelocity, DeltaTime);
				AirControlVelocity += (MovementComponent.MovementInput.ConstrainToDirection(Player.ActorRightVector) * 3000.0 * DeltaTime);

				MoveData.AddHorizontalVelocity(AirControlVelocity);
				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MoveData.RequestFallingForThisFrame();
			MoveData.InterpRotationToTargetFacingRotation(4.0);

			MovementComponent.ApplyMove(MoveData);

			if (Player.Mesh.CanRequestLocomotion())
				Player.RequestLocomotion(n"Fart", this);

			// Rotate mesh
			FQuat Roll = FQuat(Player.ActorForwardVector, -GetAttributeFloat(AttributeNames::LeftStickRawX) * 0.25);
			FQuat PitchAdjust = FQuat(Player.ActorRightVector, -0.2);
			FQuat Rotation = Roll * PitchAdjust * FQuat::MakeFromXY(MovementComponent.Velocity, Player.ActorRightVector);
			Player.MeshOffsetComponent.LerpToRotation(this, Rotation, 0.3);
		}

		// Tasty FF
		Player.SetFrameForceFeedback(0.1, 0.1, 0.5, 0.1);
		ForceFeedback::PlayDirectionalWorldForceFeedbackForFrame(Player.ActorLocation, 0.2, AffectedPlayers = EHazeSelectPlayer::Zoe);
	}

	void SetInitialVelocity()
	{
		FVector VerticalVelocity = GetVerticalImpulse();
		FVector VelocityDir = MovementComponent.MovementInput;
		if (VelocityDir.Equals(FVector::ZeroVector))
			VelocityDir = Player.ActorForwardVector;
		FVector HorizontalVelocity = VelocityDir * UPlayerAirMotionSettings::GetSettings(Player).HorizontalMoveSpeed;

		// Inherit velocity
		if (MovementComponent.GroundContact.IsValidBlockingHit())
		{
			if (MovementComponent.GroundContact.Actor != nullptr)
			{
				UPlayerInheritVelocityComponent InheritVelocityComponent = UPlayerInheritVelocityComponent::Get(MovementComponent.GroundContact.Actor);
				if (InheritVelocityComponent != nullptr)
					InheritVelocityComponent.AddFollowAdjustedVelocity(MovementComponent, HorizontalVelocity, VerticalVelocity);
			}
		}

		Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);
	}

	FVector GetVerticalImpulse() const
	{
		FVector FartForce = Player.MovementWorldUp * (MovementComponent.IsOnAnyGround() ? Pig::RainbowFart::GroundedVerticalImpulse : Pig::RainbowFart::AirborneVerticalImpluse);

		// Don't include vertical velocity if moving downwards
		FVector VerticalVelocity = Player.ActorVerticalVelocity * Math::Max(0, Player.ActorVerticalVelocity.GetSafeNormal().DotProduct(Player.MovementWorldUp));

		// Clamp so shiet doesn't go cray-zay
		return (FartForce + VerticalVelocity).GetClampedToMaxSize(FartSettings.MaxVerticalForce);
	}
}