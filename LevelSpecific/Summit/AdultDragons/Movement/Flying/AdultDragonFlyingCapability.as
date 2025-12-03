class UAdultDragonFlyingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonFlying");

	default DebugCategory = n"AdultDragon";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UAdultDragonFlightSettings FlightSettings;
	UAdultDragonAirDriftingSettings DriftSettings;
	UPlayerMovementComponent MoveComp;
	UAdultDragonFlyingComponent FlyingComp;
	UPlayerAdultDragonComponent DragonComp;

	USimpleMovementData Movement;

	float TurningTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);
		DriftSettings = UAdultDragonAirDriftingSettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		FlyingComp = UAdultDragonFlyingComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Flying, this, EInstigatePriority::Low);
		Player.ApplyCameraSettings(FlyingComp.CameraSpeedSettings, FlightSettings.CameraBlendInTime, this, SubPriority = 63);
		DragonComp.AimingInstigators.Add(this);

		TurningTimer = 0.0;
		FlyingComp.bIsFlying = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
		Player.ClearCameraSettingsByInstigator(this, FlightSettings.CameraBlendOutTime);
		Player.StopCameraShakeByInstigator(this);
		DragonComp.AimingInstigators.RemoveSingleSwap(this);
		// SpeedEffect::ClearSpeedEffect(Player, this);

		FlyingComp.bIsFlying = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if(DragonComp.Speed < FlightSettings.MinSpeed)
				{
					AccelerateTowardsMinSpeed(DeltaTime);
				}
				else
				{
					HandleAngleSpeedChange(DeltaTime);
					DragonComp.Speed += FlightSettings.ConstantAcceleration * DeltaTime;
					DragonComp.Speed = Math::Clamp(DragonComp.Speed, FlightSettings.MinSpeed, FlightSettings.MaxSpeed);
				}

				// PrintToScreen(f"Speed: {DragonComp.Speed}");

				FVector MovementInput = MoveComp.MovementInput;
				if(MovementInput.SizeSquared() > Math::Square(DriftSettings.SteeringTurningThreshold))
					TurningTimer += DeltaTime;
				else
					TurningTimer = 0;

				if(TurningTimer > DriftSettings.TurningTimerActivation)
					FlyingComp.bDriftShouldActivate = true;

				UpdateWantedRotation(DeltaTime);
				RotateTowardsWantedRotation(DeltaTime);

				FVector Velocity = Player.ActorForwardVector * DragonComp.Speed;

				HandleImpacts();
				Movement.AddDelta(Velocity * DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			UpdateSpeedEffects();
			DragonComp.RequestLocomotionDragonAndPlayer(n"AdultDragonFlying");
			MoveComp.ApplyMove(Movement);
		}
	}

	void AccelerateTowardsMinSpeed(float DeltaTime)
	{
		DragonComp.Speed += FlightSettings.Acceleration * DeltaTime;
	}

	// Accelerates going downwards and decelerates going upwards
	void HandleAngleSpeedChange(float DeltaTime)
	{
		float Pitch = Player.ActorRotation.Pitch;

		if(Pitch > 0)
		{
			float SpeedLoss = FlightSettings.SpeedLostGoingUp * Pitch * DeltaTime;
			DragonComp.Speed -= SpeedLoss;

		}
		else if(Pitch < 0)
		{
			// Pitch is negative when going down
			float SpeedGain = FlightSettings.SpeedGainedGoingDown * -Pitch * DeltaTime;
			DragonComp.Speed += SpeedGain; 
		}
	}
	
	void UpdateWantedRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		DragonComp.WantedRotation.Yaw += MovementInput.Y * FlightSettings.WantedYawSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch += MovementInput.X * FlightSettings.WantedPitchSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch = Math::Clamp(DragonComp.WantedRotation.Pitch, -FlightSettings.PitchMaxAmount, FlightSettings.PitchMaxAmount);
	}

	void RotateTowardsWantedRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		float RotationDuration = MovementInput.IsNearlyZero() ?  FlightSettings.RotationDuration : FlightSettings.RotationDurationDuringInput;
		DragonComp.RotationAccelerationDuration.AccelerateTo(RotationDuration,
													  1, 
													  DeltaTime);

		DragonComp.AccRotation.AccelerateTo(DragonComp.WantedRotation, DragonComp.RotationAccelerationDuration.Value, DeltaTime);
		Movement.SetRotation(DragonComp.AccRotation.Value);
	}
	void HandleImpacts()
	{
		if(!MoveComp.HasAnyValidBlockingContacts())
			return;
		
		FHitResult Hit;
		if(MoveComp.HasWallContact())
			Hit = MoveComp.GetWallContact().ConvertToHitResult();
		else if(MoveComp.HasGroundContact())
			Hit = MoveComp.GetGroundContact().ConvertToHitResult();
		else if (MoveComp.HasCeilingContact())
			Hit = MoveComp.GetCeilingContact().ConvertToHitResult();

		FRotator Rotation = Player.ActorRotation;
		float HitDotForward = Hit.Normal.DotProduct(Rotation.ForwardVector);

		// Slow down
		float SpeedLoss = HitDotForward * DragonComp.Speed * FlightSettings.CollisionSpeedLossMultiplier;
		// So you can't get speed when going backwards into something
		SpeedLoss = Math::Min(SpeedLoss, 0);
		DragonComp.Speed += SpeedLoss;

		FVector NewForward = Rotation.ForwardVector - Hit.Normal * HitDotForward;
		FRotator NewRotation = FRotator::MakeFromXZ(NewForward, Rotation.UpVector);
		NewRotation.Roll = 0;

		// Rotate along wall
		DragonComp.AccRotation.SnapTo(NewRotation);
		DragonComp.WantedRotation = NewRotation;

		Movement.SetRotation(NewRotation);
	}

	void UpdateSpeedEffects()
	{
		float SpeedFraction = Math::NormalizeToRange(Player.ActorVelocity.Size(), FlightSettings.MinSpeed, 
			FlightSettings.MaxSpeed);

		Player.ApplyManualFractionToCameraSettings(FlightSettings.FOVSpeedScale.GetFloatValue(SpeedFraction), this);
		Player.PlayCameraShake(FlyingComp.SpeedShake, this, FlightSettings.CameraShakeAmount.GetFloatValue(SpeedFraction));

		// SpeedEffect::RequestSpeedEffect(Player, FlightSettings.SpeedEffectValue.GetFloatValue(SpeedFraction), this, EInstigatePriority::Normal);
	}
};