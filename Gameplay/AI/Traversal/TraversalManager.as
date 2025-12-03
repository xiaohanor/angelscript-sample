struct FTraversalFindAreaData
{
	int AreaIndex = 0;
	float Range = 5000.0;
}

class UTraversalManager : UHazeTeam
{
	private uint TraversalCheckFrame = 0;
	private FInstigator TraversalCheckClaimant;
	private TMap<UScenepointComponent, ATraversalAreaActorBase> ScenepointAreaCache;
	private TMap<UScenepointComponent, FTraversalFindAreaData> FindAreaCache;

	bool CanClaimTraversalCheck(FInstigator Instigator) const
	{
		if (Time::FrameNumber > TraversalCheckFrame)
			return true;
		if (TraversalCheckClaimant == Instigator)
			return true;
		return false;
	}

	void ClaimTraversalCheck(FInstigator Instigator)
	{
		TraversalCheckFrame = Time::FrameNumber;
		TraversalCheckClaimant = Instigator;
	}

	void SetScenepointArea(UScenepointComponent Scenepoint, ATraversalAreaActorBase Area)
	{
		ScenepointAreaCache.Add(Scenepoint, Area);
		FindAreaCache.Remove(Scenepoint);
	}

	ATraversalAreaActorBase GetCachedScenepointArea(UScenepointComponent Scenepoint)
	{
		if (ScenepointAreaCache.Contains(Scenepoint))
			return ScenepointAreaCache[Scenepoint];
		return nullptr;
	}

	ATraversalAreaActorBase FindTraversalArea(UScenepointComponent Scenepoint)
	{
		if (Scenepoint == nullptr)
			return nullptr;

		ATraversalAreaActorBase CachedArea = GetCachedScenepointArea(Scenepoint);
		if (CachedArea != nullptr)
			return CachedArea;

		TArray<AHazeActor> Areas = GetMembers();
		if (!FindAreaCache.Contains(Scenepoint))
			FindAreaCache.Add(Scenepoint, FTraversalFindAreaData());
		FTraversalFindAreaData& Data = FindAreaCache[Scenepoint];

		int Cap = Math::Min(Areas.Num(), Data.AreaIndex + 100);
		FVector SpLoc = Scenepoint.WorldLocation;
		for (; Data.AreaIndex < Cap; Data.AreaIndex++)
		{
			ATraversalAreaActorBase Area = Cast<ATraversalAreaActorBase>(Areas[Data.AreaIndex]);
			if (Area == nullptr)
				continue;
			if (!Area.ActorLocation.IsWithinDist(SpLoc, Data.Range))
				continue;

			// Valid area to check in this pass
			UTraversalScenepointComponent ClosestPoint = Area.GetAnyClosestTraversalPoint(SpLoc);
			if (ClosestPoint == nullptr)
				continue;

			if (Pathfinding::HasPath(SpLoc, ClosestPoint.WorldLocation))
			{
				// Found area!
				SetScenepointArea(Scenepoint, Area);
				DebugDrawScenepointTest(Scenepoint, ClosestPoint, true);
				return Area;
			}

			// Only one path check per try
			DebugDrawScenepointTest(Scenepoint, ClosestPoint, false);
			Data.AreaIndex++;
			return nullptr;
		}
		if (Data.AreaIndex == Areas.Num())
		{
			// Try again with expanded range
			Data.AreaIndex = 0;
			if (Data.Range < 1000000.0)
				Data.Range *= 2.0;
		}
		return nullptr;
	}

	UScenepointComponent FindClosestTraversalScenepoint(FVector Location)
	{	
		UScenepointComponent ClosestPoint = nullptr;
		float ClosestDistSqr = BIG_NUMBER;
		for (auto Slot : ScenepointAreaCache)
		{
			float DistSqr = Slot.Key.WorldLocation.DistSquared(Location);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestPoint = Slot.Key;
				ClosestDistSqr = DistSqr;
			}
			
		}
		return ClosestPoint;
	}

	UScenepointComponent FindClosestTraversalScenepointOnSameElevation(FVector Location, float MaxElevationDiff = 100)
	{	
		UScenepointComponent ClosestPoint = nullptr;
		float ClosestDistSqr = BIG_NUMBER;
		for (auto Slot : ScenepointAreaCache)
		{
			if (Math::Abs(Slot.Key.WorldLocation.Z - Location.Z) > MaxElevationDiff)
				continue;

			float DistSqr = Slot.Key.WorldLocation.DistSquared(Location);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestPoint = Slot.Key;
				ClosestDistSqr = DistSqr;
			}
			
		}
		return ClosestPoint;
	}

	bool bDrawDebug = false;
	void DebugDrawScenepointTest(UScenepointComponent Point, UScenepointComponent AreaSp, bool bInArea)
	{
#if EDITOR
		//bDrawDebug = true;
		if (bDrawDebug)
		{
			FLinearColor Color = bInArea ? FLinearColor::Green : FLinearColor::Red;
			float Duration = 0.1;
			Debug::DrawDebugSphere(Point.WorldLocation + Point.UpVector * 50.0, 100.0, 8, Color, 5.0, Duration);
			Debug::DrawDebugSphere(AreaSp.WorldLocation + AreaSp.UpVector * 20.0, 50.0, 4, Color * 0.5, 3.0, Duration);
			Debug::DrawDebugLine(Point.WorldLocation + Point.UpVector * 50.0, AreaSp.WorldLocation + AreaSp.UpVector * 20.0, Color, 5.0, Duration);
		}
#endif
	}
}

