class UPlayerFindTraversalAreaCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	const float InitialRange = 5000.0;
	const float Interval = 0.5;

	UPlayerTraversalComponent TraversalComp;
	UTraversalManager TraversalManager;
	int AreaIndex = 0;
	float Range = InitialRange;
	FVector NavmeshLocation;
	float CooldownTime = 0.0;
	FVector PrevNavmeshCheckLoc = FVector(BIG_NUMBER);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TraversalComp = UPlayerTraversalComponent::GetOrCreate(Owner);
		TraversalManager = Traversal::GetManager();
		Range = InitialRange;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CooldownTime = 0.0;

		if (!PrevNavmeshCheckLoc.IsWithinDist(Owner.ActorLocation, 20.0))
		{
			NavmeshLocation = FVector(BIG_NUMBER);
			PrevNavmeshCheckLoc = Owner.ActorLocation;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float CurTime = Time::GameTimeSeconds;
		if (CurTime < CooldownTime)
			return;

		if (TraversalManager == nullptr)
			 TraversalManager = Traversal::GetManager();
		if (TraversalManager == nullptr)
		{
			CooldownTime = CurTime + Interval;
			return; // No traversal manager yet
		}

		if (NavmeshLocation == FVector(BIG_NUMBER))
		{
			if (!Pathfinding::FindNavmeshLocation(Owner.ActorLocation, 40.0, 200.0, NavmeshLocation))
			{
				CooldownTime = CurTime + Interval;
				return; // No navmesh location yet		
			}
		}

		// Keep checking until we find which traversal area we're in.
		if (!TraversalManager.CanClaimTraversalCheck(this))
			return;
		TraversalManager.ClaimTraversalCheck(this);
		
		// If we previously knew where we were, see if we're still in that same area
		FVector OwnLoc = Owner.ActorLocation;
		if (TraversalComp.CurrentArea != nullptr)
		{
			UTraversalScenepointComponent CurNearbyPoint = TraversalComp.CurrentArea.GetAnyClosestTraversalPoint(OwnLoc);
			if (!ensure(CurNearbyPoint != nullptr) || 
				!Pathfinding::HasPath(NavmeshLocation, CurNearbyPoint.WorldLocation))
			{
				// We've left that area, try to find a new one next tick
				TraversalComp.SetCurrentArea(nullptr);	
				return;
			}
			// We're still there, take a breather
			CooldownTime = CurTime + Interval;
			return;
		}

		UTraversalScenepointComponent CurNearbyPoint = TraversalComp.NearbyPoint;
		float CurNearbyDistSqr = CurNearbyPoint == nullptr ? BIG_NUMBER : CurNearbyPoint.WorldLocation.DistSquared(OwnLoc);
		TArray<AHazeActor> Areas = TraversalManager.GetMembers();
		int Cap = Math::Min(Areas.Num(), AreaIndex + 100);
		for (; AreaIndex < Cap; AreaIndex++)
		{
			ATraversalAreaActor Area = Cast<ATraversalAreaActor>(Areas[AreaIndex]);
			if (Area == nullptr)
				continue;
			if (!Area.ActorLocation.IsWithinDist(OwnLoc, Range))
				continue;

			// Valid area to check in this pass
			UTraversalScenepointComponent ClosestPointInArea = Area.GetAnyClosestTraversalPoint(OwnLoc);
			if (ClosestPointInArea == nullptr)
				continue;
			
			if (Pathfinding::HasPath(NavmeshLocation, ClosestPointInArea.WorldLocation))
			{
				// Found area!
				TraversalComp.SetCurrentArea(Area);
				CooldownTime = CurTime + 2.0;
				Range = InitialRange;
			}

			// Check if this is a closer point
			if (ClosestPointInArea.WorldLocation.DistSquared(OwnLoc) < CurNearbyDistSqr)
				TraversalComp.SetNearbyTraversalpoint(ClosestPointInArea);

			// Only one path check per tick, regardless of result
			AreaIndex++;
			return;
		}
		if (AreaIndex == Areas.Num())
		{
			// We've tried all areas within range, expand search
			AreaIndex = 0;
			if (Range < 1000000.0)
				Range *= 2.0;
		}
		// Let someone else try for a while
		CooldownTime = CurTime + Interval * 0.2;
	}
}
