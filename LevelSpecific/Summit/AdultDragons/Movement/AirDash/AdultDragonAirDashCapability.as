class UAdultDragonAirDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonFlying");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 87);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"AdultDragon";

	UPlayerAdultDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	UAdultDragonAirDashComponent AirDashComp;
	USimpleMovementData Movement;

	UAdultDragonAirDashSettings DashSettings;
	UAdultDragonFlightSettings FlightSettings;

	float SpeedAtActivation;
	float DashSpeed;
	float ClearFOVTime;
	float FOVDuration = 1.0;
	bool bFOVCleared;
	bool bFirstFrameActive = false;
	bool bHasHitWall = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		AirDashComp = UAdultDragonAirDashComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();

		DashSettings = UAdultDragonAirDashSettings::GetSettings(Player);
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!WasActionStarted(ActionNames::MovementDash))
			return false;
		
		// OBS! TEMPORARELY DISABLED
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration >= DashSettings.AirDashDuration)
			return true;

		if(bHasHitWall)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpeedAtActivation = DragonComp.Speed;
		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Dash, this, EInstigatePriority::High);
		Player.ApplyCameraSettings(AirDashComp.CameraSettings, 1.0, this, SubPriority = 61);

		UCameraSettings CamSettings = UCameraSettings::GetSettings(Player);
		CamSettings.FOV.Apply(84.0, this, 1.0, SubPriority = 63);
		ClearFOVTime = Time::GameTimeSeconds + FOVDuration;
		bFOVCleared = false;
		
		DragonComp.AnimParams.bDashInitialized = true;
		bFirstFrameActive = true;
		bHasHitWall = false;

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);

		Player.ClearCameraSettingsByInstigator(this);

		// SpeedEffect::ClearSpeedEffect(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > ClearFOVTime && !bFOVCleared)
		{
			UCameraSettings::GetSettings(Player).FOV.Clear(this, 1.5);
			Player.ClearCameraSettingsByInstigator(this, 2.0);
			bFOVCleared = true;
		}

		if(!bFirstFrameActive && DragonComp.AnimParams.bDashInitialized)
			DragonComp.AnimParams.bDashInitialized = false;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				UpdateWantedRotation(DeltaTime);
				RotateTowardsWantedRotation(DeltaTime);
				
				DashSpeed = DashSettings.SpeedCurve.GetFloatValue(ActiveDuration / DashSettings.AirDashDuration) * DashSettings.MaxAdditionalSpeed;
				DragonComp.Speed = SpeedAtActivation + DashSpeed;

				HandleImpacts();
				FVector Velocity = Player.ActorForwardVector * DragonComp.Speed;
				Movement.AddDelta(Velocity * DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			float SpeedAlpha = Math::NormalizeToRange(Player.ActorVelocity.Size(), FlightSettings.MinSpeed, FlightSettings.MaxSpeed);
			// SpeedEffect::RequestSpeedEffect(Player, SpeedAlpha * 0.3, this, EInstigatePriority::High);

			DragonComp.RequestLocomotionDragonAndPlayer(n"AdultDragonFlying");
			MoveComp.ApplyMove(Movement);
		}
		bFirstFrameActive = false;
	}

	void UpdateWantedRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		DragonComp.WantedRotation.Yaw += MovementInput.Y * DashSettings.WantedYawSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch += MovementInput.X * DashSettings.WantedPitchSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch = Math::Clamp(DragonComp.WantedRotation.Pitch, -DashSettings.PitchMaxAmount, DashSettings.PitchMaxAmount);
	}

	void RotateTowardsWantedRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		float RotationDuration = MovementInput.IsNearlyZero() ?  FlightSettings.RotationDuration : FlightSettings.RotationDurationDuringInput;
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
		float SpeedLoss = HitDotForward * DragonComp.Speed * DashSettings.CollisionSpeedLossMultiplier;
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
};