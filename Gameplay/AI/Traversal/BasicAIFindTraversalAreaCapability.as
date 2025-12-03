class UBasicAIFindTraversalAreaCapability : UHazeCapability
{
	UTraversalComponentBase TraversalComp;
	UTraversalManager TraversalManager;
	int AreaIndex = 0;
	float InitialRange = 5000.0;
	float Range = InitialRange;
	FVector NavmeshLocation;
	float CooldownTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TraversalComp = UTraversalComponentBase::GetOrCreate(Owner);
		CooldownTime = Time::GameTimeSeconds + Math::RandRange(0.0, 2.0);
		TraversalManager = Traversal::GetManager();
		Range = InitialRange;

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
		 	RespawnComp.OnRespawn.AddUFunction(TraversalComp, n"OnReset");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Time::GameTimeSeconds < CooldownTime)
			return false;
		return (TraversalComp.CurrentArea == nullptr);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CooldownTime != 0.0)
			return true;
		return (TraversalComp.CurrentArea != nullptr);		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CooldownTime = 0.0;

		NavmeshLocation = FVector(NAN_flt);
		if (!Pathfinding::FindNavmeshLocation(Owner.ActorLocation, 40.0, 200.0, NavmeshLocation))
			CooldownTime = Time::GameTimeSeconds + 0.5;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (NavmeshLocation.ContainsNaN())
			return; // No navmesh location yet		

		// Keep checking until we find which traversal area we're in.
		if (TraversalManager == nullptr)
			 TraversalManager = Traversal::GetManager();
		if (TraversalManager == nullptr)
			return;

		if (!TraversalManager.CanClaimTraversalCheck(this))
			return;
		TraversalManager.ClaimTraversalCheck(this);
		
		TArray<AHazeActor> Areas = TraversalManager.GetMembers();
		int Cap = Math::Min(Areas.Num(), AreaIndex + 100);
		FVector OwnLoc = Owner.ActorLocation;
		for (; AreaIndex < Cap; AreaIndex++)
		{
			ATraversalAreaActorBase Area = Cast<ATraversalAreaActorBase>(Areas[AreaIndex]);
			if (Area == nullptr)
				continue;
			if (!Area.ActorLocation.IsWithinDist(OwnLoc, Range))
				continue;

			// Valid area to check in this pass
			UTraversalScenepointComponent ClosestPoint = Area.GetAnyClosestTraversalPoint(OwnLoc);
			if (ClosestPoint == nullptr)
				continue;
			
			if (Pathfinding::HasPath(NavmeshLocation, ClosestPoint.WorldLocation))
			{
				// Found area!
				TraversalComp.SetCurrentArea(Area);
				CooldownTime = Time::GameTimeSeconds + 2.0;
				Range = InitialRange;
			}
			// Only one path check per tick, regardless of result
			AreaIndex++;
			return;
		}
		if (AreaIndex == Areas.Num())
		{
			AreaIndex = 0;
			if (Range < 1000000.0)
				Range *= 2.0;
		}
		// Let someone else try for a while
		CooldownTime = Time::GameTimeSeconds + 0.1;
	}
}
