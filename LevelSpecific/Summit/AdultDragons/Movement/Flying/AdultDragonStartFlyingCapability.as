class UAdultDragonStartFlyingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"AdultDragon");

	default TickGroup = EHazeTickGroup::Movement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"AdultDragon";
	
	UPlayerAdultDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;

	UAdultDragonAirBreakSettings BreakSettings;
	UAdultDragonFlightSettings FlightSettings;

	USimpleMovementData Movement;

	bool bHasActivated = false;

	float StartFlyingDuration = 2.5;
	float TimeStampConfirmPressed = BIG_NUMBER;

	FVector LaunchPosition;
	float ZOffset = 2500.0;

	float TargetSpeed = 3500.0;
	float SlowDownSpeed = 250.0;
	float Acceleration = 2500.0;
	float Decceleration = 2000.0;
	float CurrentSpeed;

	bool bCanDeactivate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		BreakSettings = UAdultDragonAirBreakSettings::GetSettings(Player);
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);

		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(DragonComp.FlightMode != EAdultDragonFlightMode::NotStarted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(MoveComp.HasMovedThisFrame())
		// 	return true;

		// if(bHasActivated
		// 	&& Time::GetGameTimeSince(TimeStampConfirmPressed) > StartFlyingDuration)
		// 	return true;
		
		if (bCanDeactivate)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasActivated = false;

		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Hover, this);
		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::MovementJump;
		Prompt.Text = NSLOCTEXT("SummitDragonLiftOff", "DragonLiftOff", "Lift Off");
		Player.ShowTutorialPrompt(Prompt, this);

		LaunchPosition = Player.ActorLocation + FVector(0.0, 0.0, ZOffset);

		Player.ApplyCameraSettings(DragonComp.StartCameraSettings, 0, this, EHazeCameraPriority::VeryHigh);

		// Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(n"AdultDragonFlying", this);
		Player.BlockCapabilities(n"AdultDragonSteering", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.SetFlightMode(EAdultDragonFlightMode::Flying);
		DragonComp.AnimationState.Clear(this);
		// Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(n"AdultDragonFlying", this);
		Player.UnblockCapabilities(n"AdultDragonSteering", this);
		Player.ClearCameraSettingsByInstigator(this, StartFlyingDuration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				// UpdateWantedRotation(DeltaTime);
				// RotateTowardsWantedRotation(DeltaTime);

				if(WasActionStarted(ActionNames::MovementJump) && !bHasActivated)
				{
					CrumbRemoveTakeOffPrompt();
					bHasActivated = true;
					TimeStampConfirmPressed = Time::GetGameTimeSeconds();
				}

				if (bHasActivated)
				{
					float Dist = (Player.ActorLocation - LaunchPosition).Size();
					FVector Direction = (LaunchPosition - Player.ActorLocation).GetSafeNormal();

					if (Dist > ZOffset / 2.0)
						CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaTime, Acceleration);
					else
						CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, SlowDownSpeed, DeltaTime, Decceleration);

					FVector Velocity = Direction * CurrentSpeed;
					Movement.AddDelta(Velocity * DeltaTime);

					if (Dist < 200.0)
						bCanDeactivate = true;
				}


				// if(bHasActivated)
				// {
				// 	DragonComp.Speed = Math::Lerp(
				// 		0,
				// 		FlightSettings.MinSpeed,
				// 		Time::GetGameTimeSince(TimeStampConfirmPressed) / StartFlyingDuration
				// 	);

				// 	DragonComp.Speed = Math::Min(DragonComp.Speed, 0);
				// 	FVector Velocity = AdultDragon.ActorForwardVector * DragonComp.Speed;
				// 	Movement.AddDelta(Velocity * DeltaTime);
				// }
				// else
				// {
				// if(WasActionStarted(ActionNames::MovementJump))
				// {
				// 	bHasActivated = true;
				// 	DragonComp.SetFlightMode(EAdultDragonFlightMode::Flying);
				// 	TimeStampConfirmPressed = Time::GetGameTimeSeconds();
				// }
				// }
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			DragonComp.RequestLocomotionDragonAndPlayer(n"AdultDragonFlying");
			MoveComp.ApplyMove(Movement);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbRemoveTakeOffPrompt()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	void UpdateWantedRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		DragonComp.WantedRotation.Yaw += MovementInput.Y * BreakSettings.WantedYawSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch += MovementInput.X * BreakSettings.WantedPitchSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch = Math::Clamp(DragonComp.WantedRotation.Pitch, -BreakSettings.PitchMaxAmount, BreakSettings.PitchMaxAmount);
	}

	void RotateTowardsWantedRotation(float DeltaTime)
	{
		DragonComp.AccRotation.AccelerateTo(DragonComp.WantedRotation, BreakSettings.RotationAcceleration, DeltaTime);
		Movement.SetRotation(DragonComp.AccRotation.Value);
	}
};