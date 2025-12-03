class UPinballPlungerPullBackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	APinballPlunger Plunger;
	bool bHasHitBottom = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Plunger = Cast<APinballPlunger>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Plunger.HasAppliedLocationThisFrame())
			return false;

		// We can never enter PullBack from LaunchForward
		if(Plunger.State == EPinballPlungerState::LaunchForward)
			return false;

		if(!Plunger.bIsHolding)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Plunger.HasAppliedLocationThisFrame())
			return true;

		if(Plunger.State != EPinballPlungerState::PullBack)
			return true;

		if(!Plunger.bIsHolding)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Plunger.State = EPinballPlungerState::PullBack;
		Plunger.BlockFollowComp.ApplyBlockFollow(false, this);

		if(Math::Abs(Plunger.PlungerSpeed) > Plunger.PullBackMaxSpeed)
			Plunger.PlungerSpeed = Math::Sign(Plunger.PlungerSpeed) * Plunger.PullBackMaxSpeed;

		UPinballPlungerEventHandler::Trigger_OnStartPullBack(Plunger);

		bHasHitBottom = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Plunger.BlockFollowComp.ClearBlockFollow(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Accelerate back
		Plunger.PlungerSpeed -= Plunger.PullBackAcceleration * DeltaTime;

		// Limit max speed
		if(Plunger.PlungerSpeed < -Plunger.PullBackMaxSpeed)
			Plunger.PlungerSpeed = -Plunger.PullBackMaxSpeed;

		// Move back
		Plunger.PlungerDistance += Plunger.PlungerSpeed * DeltaTime;

		if(Plunger.PlungerDistance < -Plunger.PullBackDistance)
		{
			// Stop when we reach max pull back distance
			Plunger.PlungerDistance = -Plunger.PullBackDistance;
			Plunger.PlungerSpeed = 0;

			if(!bHasHitBottom)
			{
				UPinballPlungerEventHandler::Trigger_OnReachBottom(Plunger);
				bHasHitBottom = true;
			}
		}

		float Intensity = 0.1 + (Math::Abs(Math::Sin(Time::GameTimeSeconds))*0.2); 
		ForceFeedback::PlayDirectionalWorldForceFeedbackForFrame(Game::Mio.ActorLocation,Intensity,100,0,0,EHazeSelectPlayer::Mio,false);

		Plunger.ApplyLocation();
	}
};