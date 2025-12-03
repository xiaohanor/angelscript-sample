class UFlyingPathfollowingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Pathfinding");

	// This should run between anything setting destination and movement capability 
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPathfollowingMoveToComponent MoveToComp;
	UPathfollowingSettings Settings;
	FVector OwnPrevLoc;
	FVector PrevDestination;
	FVector LastStartLocation;
	bool bAccuratePath = false;
	float InaccurateRetryTime = 0.0;
	float OwnerSize = 40.0;

	FVector LastKnownOctreeLocation = FVector(BIG_NUMBER);
	FVector LastOwnLocationWhenOctreeLocWasKnown = FVector(-BIG_NUMBER);
	float OctreeLocationCheckTime = 0.0;

	TArray<FHazeNavOctreePathNode> RawOctreePath;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveToComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		Settings = UPathfollowingSettings::GetSettings(Owner);
		FVector DummyOrigin;
		FVector Bounds;
		Owner.GetActorBounds(true, DummyOrigin, Bounds, false);
		OwnerSize = Math::Max(Bounds.Y * 0.707, 16.0); // 0.707 because of cubic bounds while actual collision is usually spherical
	}	

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		MoveToComp.Path.Reset();
		MoveToComp.PathIndex = -1;
		OwnPrevLoc = Owner.ActorLocation;
		PrevDestination = OwnPrevLoc;
		LastStartLocation = OwnPrevLoc;
		bAccuratePath = false;
		InaccurateRetryTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Only active on control side when we want to move somewhere
		if (!HasControl())
            return false;
        if (!MoveToComp.HasDestination())
			return false;	
		if (Settings.bIgnorePathfinding)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HasControl())
            return true;
        if (!MoveToComp.HasDestination())
			return true;
		if (Settings.bIgnorePathfinding)
			return true;
		return false;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated()
    {
		Reset();
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector Destination = MoveToComp.FinalDestination;
		if (NeedsNewPath())
		{
			EBasicPathfindingResult Result = FindPath(OwnLoc, Destination, MoveToComp.PathIndex);
			LastStartLocation = OwnLoc;
			bAccuratePath = (Result == EBasicPathfindingResult::AccuratePath);
			if (bAccuratePath)
				InaccurateRetryTime = 0.0;
			else if (Time::GameTimeSeconds > InaccurateRetryTime)
				InaccurateRetryTime = Time::GameTimeSeconds + 2.0; // Settings.BadPathRetryInterval
			ReportResult(Result);
		}

		// We're moving along path, have we reached current node?
		if (IsAt(MoveToComp.PathIndex))
		{
			LastKnownOctreeLocation = MoveToComp.Path.Points[MoveToComp.PathIndex];
			LastOwnLocationWhenOctreeLocWasKnown = OwnLoc;
			OctreeLocationCheckTime = Time::GameTimeSeconds + 0.5;
			
			// Go to next node!
			MoveToComp.PathIndex++;
		}
		else if ((Time::GameTimeSeconds > OctreeLocationCheckTime) && !OwnLoc.IsWithinDist(LastOwnLocationWhenOctreeLocWasKnown, 100.0))
		{
			// Check intermittently if we know where we are in octtree. This is used as backup when we find start location on wrong side of walls.
			FVector OctreeLoc;
			if (Navigation::NavOctreeGetNearestLocationInTree(OwnLoc, 8.0, OwnerSize, OctreeLoc))
			{
				LastKnownOctreeLocation = OctreeLoc;
				LastOwnLocationWhenOctreeLocWasKnown = OwnLoc;
				OctreeLocationCheckTime = Time::GameTimeSeconds + 0.5; 
			}
		}

		if (MoveToComp.Path.IsValidPathIndex(MoveToComp.PathIndex))
		{
			if (MoveToComp.PathIndex < MoveToComp.Path.Points.Num() - 1)
			{
				// Not at end of path, move towards next path node
				MoveToComp.SetPathfindingDestination(GetPathLocation(MoveToComp.PathIndex));
			}
			else
			{
				// We're at last leg of path
				if (bAccuratePath)
				{
					// Move directly to destination
					MoveToComp.SetPathfindingDestination(Destination);
				}
				else 
				{
					// Inaccurate path, always go to last path location before venturing outside navmesh
					MoveToComp.SetPathfindingDestination(GetPathLocation(MoveToComp.Path.Points.Num() - 1));
				}
			}
		}
		else if (bAccuratePath)
		{
			// We're moving to final destination
			MoveToComp.SetPathfindingDestination(Destination);					
		}
		else
		{
			// We're as close as we can get within nav mesh or we could not find a path at all.
			MoveToComp.SetPathfindingDestination(OwnLoc);					
		}

		OwnPrevLoc = Owner.ActorLocation;
		PrevDestination = Destination;

		DebugDrawPath(OwnLoc, Destination, bAccuratePath);
	}

	FVector GetPathLocation(int Index)
	{
		return MoveToComp.Path.Points[Index];
	}

	bool NeedsNewPath()
	{
		if (!MoveToComp.Path.IsValid())
			return true;

		if (MoveToComp.Path.Points.Num() == 0)
			return true;

		if (bAccuratePath)
		{
			// We only need new path if destination has moved a lot.
			if (MoveToComp.FinalDestination.DistSquared(MoveToComp.Path.Points.Last()) > Math::Square(Settings.UpdatePathDistance))
				return true;
	
			return false;
		}
		else 
		{
			// Inaccurate path, so starting or ending outside of navmesh
			// Try for a new path if destination has moved a bit
			if (!MoveToComp.FinalDestination.IsWithinDist(PrevDestination, Settings.UpdatePathDistance))
				return true;			

			// Try for a new path every once in a while
			if (Time::GameTimeSeconds > InaccurateRetryTime)
				return true;

			return false;
		}
	}

	EBasicPathfindingResult FindPath(FVector Start, FVector Destination, int& OutPathIndex)
	{
		// Scrap previous path
		MoveToComp.Path.Reset();

		FVector PathStart;
		if (!Navigation::NavOctreeGetNearestLocationInTree(Start, Settings.NavmeshMaxProjectionRange, OwnerSize, PathStart))
			return EBasicPathfindingResult::BadStart;

		FVector PathDest;
		if (!Navigation::NavOctreeGetNearestLocationInTree(Destination, Settings.NavmeshMaxProjectionRange, OwnerSize, PathDest))
			return EBasicPathfindingResult::BadDestination;

		RawOctreePath.Empty();
		bool bFoundPath = Navigation::NavOctreeFindPath(PathStart, PathDest, OwnerSize, 0.0, RawOctreePath);
		if (!bFoundPath || !PostProcessPath(PathStart, PathDest, RawOctreePath, MoveToComp.Path))
			return EBasicPathfindingResult::NoPath;

		// We have a new path to follow
		OutPathIndex = 1;

		// Is destination outside navmesh?
		if (!MoveToComp.Path.Points.Last().IsWithinDist(Destination, Settings.OutsideNavmeshEndRange + OwnerSize))
			return EBasicPathfindingResult::InaccuratePath;

		// Are we starting outside navmesh?
		if (!MoveToComp.Path.Points[0].IsWithinDist(Start, Settings.OutsideNavmeshStartRange + OwnerSize))
			return EBasicPathfindingResult::InaccuratePath;

		// Path is good
		return EBasicPathfindingResult::AccuratePath;
	}

	bool PostProcessPath(FVector PathStart, FVector PathDest, TArray<FHazeNavOctreePathNode> OctreePath, FNavigationPath& FinalPath)
	{
		OctreePath.FunnelPath(PathStart, PathDest, OwnerSize, FinalPath);
		return FinalPath.IsValid();
	}

	bool IsAt(int Index)
	{
		// If we have no path or have moved past last node we will not continue
		if (!MoveToComp.Path.IsValidPathIndex(Index))
			return false;

		// Check if close enough
		bool bIsDestination = (Index >= MoveToComp.Path.Points.Num() - 1);
		float Range = bIsDestination ? Settings.AtDestinationRange : Settings.AtWaypointRange;
		FVector OwnLoc = Owner.ActorLocation;
		FVector PathLoc = MoveToComp.Path.Points[Index];
		if (bAccuratePath && bIsDestination)
			PathLoc = MoveToComp.FinalDestination;
		if (Pathfinding::IsPathNear(OwnLoc, PathLoc, Range, 0.0))
			return true;

		// Check for overshoot
		FVector PrevPathLoc = (Index > 0) ? MoveToComp.Path.Points[Index - 1] : LastStartLocation;
		FVector ToPath = PathLoc - OwnLoc;
		if (ToPath.DotProduct(PathLoc - PrevPathLoc) < 0.0)
			return true;

		return false;
	}

	void ReportResult(EBasicPathfindingResult Result)
	{
		if (Result == EBasicPathfindingResult::BadStart)
			MoveToComp.ReportFailed(EPathfollowingMoveToFailReason::BadStart);
		else if (Result == EBasicPathfindingResult::BadDestination)
			MoveToComp.ReportFailed(EPathfollowingMoveToFailReason::BadDestination);
		else if (Result == EBasicPathfindingResult::NoPath)
			MoveToComp.ReportFailed(EPathfollowingMoveToFailReason::NoPath);
	}

	void DebugDrawPath(FVector Start, FVector Destination, bool bDrawAccuratePath)
	{
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (!Owner.bHazeEditorOnlyDebugBool)
			return;

		//MoveToComp.Path.DrawDebugSpline(FLinearColor::Purple);
		//MoveToComp.Path.DrawDebugTurns(800.0, FLinearColor::Blue);

		RawOctreePath.DrawDebugPath();
		if (MoveToComp.Path.Points.Num() > 0) RawOctreePath.DrawDebugFunnelling(MoveToComp.Path.Points[0], MoveToComp.Path.Points.Last());

		Debug::DrawDebugSphere(Destination, 10, 4, FLinearColor::Green);

		if (LastOwnLocationWhenOctreeLocWasKnown.IsWithinDist(Owner.ActorLocation, 2000.0))
		{
			// TODO: Limit this to one AI each frame
			Debug::DrawDebugSphere(LastKnownOctreeLocation, 5, 4, FLinearColor::Purple * 0.5, 5);
			Debug::DrawDebugSphere(LastOwnLocationWhenOctreeLocWasKnown, 4, 4, FLinearColor::DPink * 0.5, 3);
			Debug::DrawDebugLine(Owner.ActorLocation, LastKnownOctreeLocation, FLinearColor::Purple * 0.5, 0);
			Debug::DrawDebugLine(LastOwnLocationWhenOctreeLocWasKnown, LastKnownOctreeLocation, FLinearColor::DPink * 0.5, 0);
		}

		if (!MoveToComp.Path.IsValid())
		{
			Debug::DrawDebugLine(Start, Destination, FLinearColor::Red, 0.0);
			FVector PathStart;
			if (Navigation::NavOctreeGetNearestLocationInTree(Start, Settings.NavmeshMaxProjectionRange, OwnerSize, PathStart))
			{
				Debug::DrawDebugSphere(PathStart, 10, 4, FLinearColor::LucBlue, 5);
				Debug::DrawDebugLine(PathStart, Start, FLinearColor::Red, 0.0);
			}
			else
			{
				Debug::DrawDebugSphere(Start, 10, 4, FLinearColor::Red, 5);
			}
			FVector PathDest;
			if (Navigation::NavOctreeGetNearestLocationInTree(Destination, Settings.NavmeshMaxProjectionRange, OwnerSize, PathDest))
			{
				Debug::DrawDebugSphere(PathDest, 10, 4, FLinearColor::Blue, 5);
				Debug::DrawDebugLine(PathDest, Destination, FLinearColor::Red, 0.0);
			}
			else
			{
				Debug::DrawDebugSphere(Destination, 10, 4, FLinearColor::Yellow, 5);
			}
			return;
		}
		
		if (MoveToComp.Path.Points.Num() == 1)
			Debug::DrawDebugLine(Start, MoveToComp.Path.Points[0], FLinearColor::Blue, 0.0, 0.0);

		//MoveToComp.Path.DrawDebug(DrawOffset, FLinearColor::LucBlue);

		// System::DrawDebugLine(Start + DrawOffset, MoveToComp.FinalDestination + DrawOffset, FLinearColor::White, 0.0, 0.5);
		// for (FVector PointLoc : MoveToComp.Path.Points) {System::DrawDebugLine(PointLoc, PointLoc + DrawOffset * 10.0, FLinearColor::Yellow, 0.0, 2.0);}
		// for (FVector PointLoc : MoveToComp.Path.Points) {System::DrawDebugLine(PointLoc, Start, FLinearColor::Red, 0.0, 2.0);}
#endif		
	}
}

