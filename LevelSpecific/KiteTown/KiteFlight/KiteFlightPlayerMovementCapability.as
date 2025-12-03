class UKiteFlightPlayerMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(KiteTags::KiteFlight);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	UKiteFlightPlayerComponent KiteFlightComp;
	UHazeCrumbSyncedVector2DComponent BlendSpaceSyncComp;

	float CurrentPitch = 0.0;
	float CurrentRoll = 0.0;

	FHazeAcceleratedFloat AccForwardSpeed;
	FHazeAcceleratedFloat AccSideSpeed;
	FHazeAcceleratedFloat AccVerticalSpeed;

	float MoveInputMultiplier = 0.0;
	FHazeAcceleratedVector2D AccMoveInput;
	FRotator Rotation;

	bool bLostVelocity = false;

	bool bInitialDirectionReached = false;
	FVector InitialDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		KiteFlightComp = UKiteFlightPlayerComponent::Get(Player);

		BlendSpaceSyncComp = UHazeCrumbSyncedVector2DComponent::GetOrCreate(Player, n"KiteFlightBlendSpaceSync");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KiteFlightComp.bFlightActive)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!KiteFlightComp.bFlightActive)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.IsOnAnyGround())
			return true;

		if (bLostVelocity)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bLostVelocity = false;
		bInitialDirectionReached = false;
		InitialDirection = KiteFlightComp.InitialDirection;
		AccForwardSpeed.SnapTo(KiteFlight::MinSpeed + KiteFlightComp.CurrentBoostValue);
		MoveInputMultiplier = 0.0;
		BlendSpaceSyncComp.SetValue(FVector2D(0.0, 0.0));

		AccSideSpeed.SnapTo(0.0);
		AccMoveInput.SnapTo(FVector2D::ZeroVector);
		AccVerticalSpeed.SnapTo(0.0);

		CurrentPitch = 0.0;
		CurrentRoll = 0.0;

		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		Player.ApplyCameraSettings(KiteFlightComp.CamSettings, 2.0, this, EHazeCameraPriority::Medium);

		Player.PlayCameraShake(KiteFlightComp.FlyCamShake, this, 0.5);

		KiteFlightComp.TriggerBoost(KiteFlight::InitialBoost);

		Rotation = Player.ViewRotation;

		UKiteFlightPlayerEffectEventEventHandler::Trigger_ActivateFlight(Player);
		UKiteTownVOEffectEventHandler::Trigger_ActivateFlight(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);

		Player.StopSlotAnimation();

		Player.ClearCameraSettingsByInstigator(this);
		Player.StopCameraShakeByInstigator(this);

		SpeedEffect::ClearSpeedEffect(Player, this);

		KiteFlightComp.DeactivateFlight();

		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.2);

		UKiteFlightPlayerEffectEventEventHandler::Trigger_DeactivateFlight(Player);
		UKiteTownVOEffectEventHandler::Trigger_DeactivateFlight(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if (!bInitialDirectionReached)
				{
					Rotation = Math::RInterpShortestPathTo(Rotation, InitialDirection.Rotation(), DeltaTime, 6.0);
					if (Rotation.Equals(InitialDirection.Rotation(), 2.0))
						bInitialDirectionReached = true;
				}

				FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

				if (KiteFlightComp.ControlMode == EKiteFlightControlMode::Movement)
				{
					if (bInitialDirectionReached)
					{
						FVector2D CameraInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

						MoveInputMultiplier = Math::FInterpConstantTo(MoveInputMultiplier, 1.0, DeltaTime, 2.0);
						float HoriInput = Math::Clamp(MoveInput.X + CameraInput.Y, -1.0, 1.0) * MoveInputMultiplier;
						float VertInput = Math::Clamp(MoveInput.Y + CameraInput.X, -1.0, 1.0) * MoveInputMultiplier;
						MoveInput = FVector2D(HoriInput, VertInput);

						if (Player.IsSteeringPitchInverted())
							MoveInput.X *= -1.0;

						AccMoveInput.AccelerateTo(MoveInput, 1.0, DeltaTime);	
						Rotation.Pitch = Math::Clamp(Rotation.Pitch + (AccMoveInput.Value.X * KiteFlight::TurnSpeed * DeltaTime), -KiteFlight::MaxPitch, KiteFlight::MaxPitch);
						Rotation.Yaw += AccMoveInput.Value.Y * KiteFlight::TurnSpeed * DeltaTime;
					}

					Player.SetCameraDesiredRotation(Rotation, this);
				}

				FVector MoveDirection;
				FVector CameraForward = Player.ViewRotation.ForwardVector;
				float TargetForwardSpeed = Math::Clamp(KiteFlight::MinSpeed + KiteFlightComp.CurrentBoostValue, KiteFlight::MinSpeed, KiteFlight::GetMaxSpeedWithRubberbanding(Player));
				AccForwardSpeed.AccelerateTo(TargetForwardSpeed, 0.5, DeltaTime);
				MoveDirection += CameraForward * AccForwardSpeed.Value;

				KiteFlightComp.ForwardSpeedSyncComp.SetValue(AccForwardSpeed.Value);

				if (KiteFlightComp.ControlMode == EKiteFlightControlMode::Camera)
				{
					FVector CameraRight = Player.ViewRotation.RightVector;
					AccSideSpeed.AccelerateTo(MoveInput.Y * KiteFlight::StrafeSpeed, 0.75, DeltaTime);
					MoveDirection += CameraRight * AccSideSpeed.Value;

					float VerticalVelocity = MoveInput.X;
					if (IsActioning(ActionNames::MovementVerticalUp))
						VerticalVelocity += 1.0;
					else if (IsActioning(ActionNames::MovementVerticalDown))
						VerticalVelocity -= 1.0;

					VerticalVelocity = Math::Clamp(VerticalVelocity, -1.0, 1.0);

					FVector CameraUp = Player.ViewRotation.UpVector;
					AccVerticalSpeed.AccelerateTo(VerticalVelocity * KiteFlight::StrafeSpeed, 1.0, DeltaTime);
					MoveDirection += CameraUp * AccVerticalSpeed.Value;
				}

				FVector MoveDelta = MoveDirection * DeltaTime;
				Movement.AddDelta(MoveDelta);
				Movement.SetRotation(Player.ViewRotation);

				if (Math::IsNearlyEqual(AccForwardSpeed.Value, KiteFlight::MinSpeed, 10.0))
				{
					bLostVelocity = true;
				}

				BlendSpaceSyncComp.SetValue(FVector2D(MoveInput.Y, MoveInput.X));
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			float TargetPitch = Player.ViewRotation.Pitch;
			CurrentPitch = Math::FInterpTo(CurrentPitch, TargetPitch, DeltaTime, 5.0);
			Player.MeshOffsetComponent.SnapToRotation(this, FRotator(CurrentPitch, Player.ViewRotation.Yaw, 0.0).Quaternion());
			CurrentRoll = Math::FInterpTo(CurrentRoll, BlendSpaceSyncComp.Value.X, DeltaTime, 5.0);
			Player.SetBlendSpaceValues(CurrentRoll, 0.0);

			// MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
			MoveComp.ApplyMove(Movement);

			float FFIntensity = Math::Lerp(0.1, 0.3, KiteFlightComp.GetSpeedAlpha());
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(ActiveDuration * 20.0) * FFIntensity;
			FF.RightMotor = Math::Sin(-ActiveDuration * 20.0) * FFIntensity;
			Player.SetFrameForceFeedback(FF);
		}

		float SpeedEffectValue = Math::Lerp(0.5, 1.5, KiteFlightComp.GetSpeedAlpha());
		SpeedEffect::RequestSpeedEffect(Player, SpeedEffectValue, this, EInstigatePriority::High);
	}
}