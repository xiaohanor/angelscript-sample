class UStoneBeastThrowingRockMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStoneBeastThrowingRock Rock;

	float LifeTime = 13.0;
	float TargetSpeed = 10500.0;

	FHazeAcceleratedVector AccelToStartVec;
	FHazeAcceleratedFloat AccelToTargetSpeed;
	FVector ToTargetDirection;

	bool bGoingToStart;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rock = Cast<AStoneBeastThrowingRock>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Rock.bRockActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (LifeTime <= 0.0)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelToStartVec.SnapTo(Rock.ActorLocation);
		bGoingToStart = true;
		Rock.LightningComp.Activate();
		FStoneBeastThrowingRockParams Params;
		Params.Location = Rock.ActorLocation;
		UStoneBeastThrowingRockEventHandler::Trigger_StartRockPickup(Rock, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rock.bRockActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bGoingToStart)
		{
			AccelToStartVec.AccelerateTo(Rock.GoToLoc, 2.25, DeltaTime);
			Rock.ActorLocation = AccelToStartVec.Value; 

			if ((Rock.ActorLocation - Rock.GoToLoc).Size() <= 200.0)
			{
				bGoingToStart = false;
				FVector ToLoc = Rock.TargetPlayer.ActorLocation;
				ToTargetDirection = (ToLoc - Rock.ActorLocation).GetSafeNormal();
				Rock.LightningComp.Deactivate();
				FStoneBeastThrowingRockParams StartParams;
				StartParams.Location = Rock.ActorLocation;
				UStoneBeastThrowingRockEventHandler::Trigger_StartRockPickup(Rock, StartParams);
			}
		}
		else
		{
			//NOTE Collision from this already kills the player due to their Damage capability
			AccelToTargetSpeed.AccelerateTo(TargetSpeed, 1.0, DeltaTime);
			Rock.ActorLocation += ToTargetDirection * AccelToTargetSpeed.Value * DeltaTime;
		}

		FStoneBeastThrowingRockParams UpdateParams;
		UpdateParams.Location = Rock.ActorLocation;
		Rock.UpdateLoopingLighting();
		LifeTime -= DeltaTime;
	}
};