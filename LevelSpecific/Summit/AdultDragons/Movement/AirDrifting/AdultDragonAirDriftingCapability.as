class UAdultDragonAirDriftingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonAirDrifting");
	default CapabilityTags.Add(n"AdultDragonFlying");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 99;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 89);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"AdultDragon";

	UPlayerMovementComponent MoveComp;
	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonAirDriftingComponent DriftComp;
	UAdultDragonFlyingComponent FlyingComp;

	USimpleMovementData Movement;

	UAdultDragonAirDriftingSettings Settings;
	UAdultDragonFlightSettings FlightSettings;

	bool bHasHitWall = false;

	float DriftRotationDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		DriftComp = UAdultDragonAirDriftingComponent::Get(Player);
		FlyingComp = UAdultDragonFlyingComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();

		Settings = UAdultDragonAirDriftingSettings::GetSettings(Player);
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;
		
		if(!FlyingComp.bDriftShouldActivate)
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		FVector Input = MoveComp.MovementInput;
		
		if(Input.SizeSquared() < Math::Square(Settings.SteeringTurningThreshold))
			return true;

		if(bHasHitWall)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FlyingComp.bDriftShouldActivate = false;
		bHasHitWall = false;
		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Flying, this);
		DragonComp.AimingInstigators.Add(this);

		Player.ApplyCameraSettings(DriftComp.CameraSettings, Settings.CameraBlendInDuration, this, SubPriority = 62);

		DriftComp.bIsDrifting = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
		DragonComp.AimingInstigators.RemoveSingleSwap(this);

		Player.StopCameraShakeByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, Settings.CameraBlendOutDuration);
		// SpeedEffect::ClearSpeedEffect(Player, this);

		DriftComp.bIsDrifting = false;
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
		DragonComp.WantedRotation.Yaw += MovementInput.Y * Settings.WantedYawSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch += MovementInput.X * Settings.WantedPitchSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch = Math::Clamp(DragonComp.WantedRotation.Pitch, -Settings.PitchMaxAmount, Settings.PitchMaxAmount);
	}

	void RotateTowardsWantedRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		float RotationDuration = MovementInput.IsNearlyZero() ?  Settings.RotationDuration : Settings.RotationDurationDuringInput;
		DragonComp.RotationAccelerationDuration.AccelerateTo(RotationDuration,
													  0.5, 
													  DeltaTime);

		DragonComp.AccRotation.AccelerateTo(DragonComp.WantedRotation, DragonComp.RotationAccelerationDuration.Value, DeltaTime);
		Movement.SetRotation(DragonComp.AccRotation.Value);
	}

	void HandleImpacts()
	{
		if(!MoveComp.HasAnyValidBlockingContacts())
			return;
		
		FMovementHitResult Hit;
		if(MoveComp.HasWallContact())
			Hit = MoveComp.GetWallContact();
		else if(MoveComp.HasGroundContact())
			Hit = MoveComp.GetGroundContact();
		else if (MoveComp.HasCeilingContact())
			Hit = MoveComp.GetCeilingContact();

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
		bHasHitWall = true;
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