class USummitAdultDragonCircleStrafeManagerAttackRunCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitAdultDragonCircleStrafeManager StrafeManager;

	FHazeAcceleratedVector AccSplinePosFollow;

	TPerPlayer<UAdultDragonCircleStrafeComponent> CircleStrafeComps;

	bool bOnePlayerHasReachedEnd = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StrafeManager = Cast<ASummitAdultDragonCircleStrafeManager>(Owner);

		for(auto Player : Game::Players)
		{
			CircleStrafeComps[Player] = UAdultDragonCircleStrafeComponent::GetOrCreate(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(StrafeManager.CurrentState != ESummitAdultDragonCircleStrafeState::AttackRun)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bOnePlayerHasReachedEnd)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bOnePlayerHasReachedEnd = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(auto CircleStrafeComp : CircleStrafeComps)
		{
			CircleStrafeComp.bSmoothenTransition = true;
		}
		StrafeManager.SetCircleStrafeState(ESummitAdultDragonCircleStrafeState::Circling);

		UpdateCameraRotation();	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(auto CircleStrafeComp : CircleStrafeComps)
		{
			if(CircleStrafeComp.bHasReachedEndOfAttackRunSpline)
			{
				bOnePlayerHasReachedEnd = true;
			}
		}
	}

	void UpdateCameraRotation()
	{
		FVector AveragePlayerEndLocation;
		for(auto Player : Game::Players)
		{
			AveragePlayerEndLocation += Player.ActorLocation;
		}
		AveragePlayerEndLocation *= 0.5;

		FVector DirManagerToPlayers = (AveragePlayerEndLocation - StrafeManager.ActorLocation).GetSafeNormal();
		StrafeManager.SetActorRotation(FRotator::MakeFromX(DirManagerToPlayers));
		// StrafeManager.CurrentSplinePos = StrafeManager.SplineToFollow.Spline.GetClosestSplinePositionToWorldLocation(AveragePlayerEndLocation);
		// StrafeManager.SetActorLocation(StrafeManager.CurrentSplinePos.WorldLocation);

		// AActor Boss = StrafeManager.Boss;
		// FVector DirToBoss = (Boss.ActorLocation - StrafeManager.ActorLocation).GetSafeNormal();
		// FRotator FacingBoss = FRotator::MakeFromX(DirToBoss);
		// StrafeManager.SetActorRotation(FacingBoss);
	}
};