class UWallclimbingPathfollowingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Pathfinding");

	// Runs on control side only
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	// This should run between anything setting destination and movement capability 
	default TickGroup = EHazeTickGroup::BeforeMovement;

	float FindNavigationTime = 0;

	UPathfollowingMoveToComponent MoveToComp;
	UPathfollowingSettings Settings;
	UWallclimbingPathfollowingSettings WallclimbingSettings;
	UWallclimbingComponent WallclimbingComp;
	FVector OwnPrevLoc;
	FVector PrevDestination;
	FVector LastStartLocation;
	bool bAccuratePath = false;
	float InaccurateRetryTime = 0.0;
	float OwnerSize = 40.0;

	float UpdateOctreeLocationTime = 0.0;
	FVector LastKnownCheckLocation = FVector(BIG_NUMBER);
	FVector LastKnownOctreeLocation = FVector(BIG_NUMBER);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveToComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		WallclimbingComp = UWallclimbingComponent::GetOrCreate(Owner);
		Settings = UPathfollowingSettings::GetSettings(Owner);
		WallclimbingSettings = UWallclimbingPathfollowingSettings::GetSettings(Owner);
		FVector DummyOrigin;
		FVector Bounds;
		Owner.GetActorBounds(true, DummyOrigin, Bounds, false);
		OwnerSize = Math::Max(Bounds.Y, 16.0);
	}	

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		WallclimbingComp.Reset();
		MoveToComp.Path.Reset();
		MoveToComp.PathIndex = -1;
		OwnPrevLoc = PathingLocation;
		PrevDestination = OwnPrevLoc;
		LastStartLocation = OwnPrevLoc;
		bAccuratePath = false;
		InaccurateRetryTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (WallclimbingComp.Navigation != nullptr)
			return;
		if (Time::GameTimeSeconds < FindNavigationTime)
			return;
		WallclimbingComp.Navigation = Wallclimbing::GetNavigationVolume(PathingLocation, OwnerSize);
		FindNavigationTime = Time::GameTimeSeconds + 2.0;
	}

	FVector GetPathingLocation() const property
	{
		return Owner.ActorLocation + Owner.ActorUpVector * OwnerSize;
	}

	FVector GetPathingDestination(FVector Destination) const
	{
		// TODO: Will work poorly when destination is on surface with normal different from our current
		return Destination + Owner.ActorUpVector * OwnerSize;;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Only active on control side when we want to move somewhere
		if (!HasControl())
            return false;
        if (!MoveToComp.HasDestination())
			return false;	
		if (WallclimbingComp.Navigation == nullptr)
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
		// TODO: This can be expensive if we move on and off towards the same general destination, investigate
		Reset();
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = PathingLocation;
		FVector Destination = MoveToComp.FinalDestination; // Can't use pathingdestination since we don't know what our up vector will be when reaching destination
		if (NeedsNewPath())
		{
			EBasicPathfindingResult Result = FindPath(OwnLoc, Owner.ActorUpVector, Destination, WallclimbingComp.DestinationUpVector.Get(), MoveToComp.PathIndex);
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
			MoveToComp.PathIndex++;

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
					MoveToComp.SetPathfindingDestination(MoveToComp.FinalDestination);
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

		OwnPrevLoc = PathingLocation;
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
			if (!Pathfinding::IsPathNear(MoveToComp.FinalDestination, MoveToComp.Path.Points.Last(), Settings.UpdatePathDistance, WallclimbingSettings.AtPointHeightTolerance, Owner.ActorUpVector))
				return true;
	
			return false;
		}
		else 
		{
			// Inaccurate path, so starting or ending outside of navmesh
			// Try for a new path if destination has moved a bit
			if (!Pathfinding::IsPathNear(MoveToComp.FinalDestination, PrevDestination, Settings.UpdatePathDistance, WallclimbingSettings.AtPointHeightTolerance, Owner.ActorUpVector))
				return true;			

			// Try for a new path every once in a while
			if (Time::GameTimeSeconds > InaccurateRetryTime)
				return true;

			return false;
		}
	}

	EBasicPathfindingResult FindPath(FVector Start, FVector StartNormal, FVector Destination, FVector DestinationNormal, int& OutPathIndex)
	{
		// Scrap previous path
		MoveToComp.Path.Reset();
		WallclimbingComp.Path.Empty();
		float VerticalTolerance = OwnerSize + WallclimbingSettings.NavmeshMaxProjectionHeight;
		float HorizontalTolerance = OwnerSize + WallclimbingSettings.NavmeshMaxProjectionWidth;
		if (!WallclimbingComp.Navigation.FindPath(Start, StartNormal, Destination, DestinationNormal, OwnerSize, VerticalTolerance, HorizontalTolerance, WallclimbingComp.Path))
		{
			// No path, check why
			if (WallclimbingComp.Navigation.FindPoly(Start, StartNormal, OwnerSize, VerticalTolerance, HorizontalTolerance) == -1)
				return EBasicPathfindingResult::BadStart;
			if (WallclimbingComp.Navigation.FindPoly(Destination, DestinationNormal, OwnerSize, VerticalTolerance, HorizontalTolerance) == -1)
				return EBasicPathfindingResult::BadDestination;
			return EBasicPathfindingResult::NoPath;
		}

		// We have a new path to follow
		OutPathIndex = 1;
		for (FWallClimbingPathNode Node : WallclimbingComp.Path)
		{
			MoveToComp.Path.Points.Add(Node.Location);	
		}	

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
		FVector OwnLoc = PathingLocation;
		FVector PathLoc = MoveToComp.Path.Points[Index];
		if (bAccuratePath && bIsDestination)
			PathLoc = MoveToComp.FinalDestination;
		FVector UpVector = WallclimbingComp.Path[Index].Normal;
		if (Pathfinding::IsPathNear(OwnLoc, PathLoc, Range, WallclimbingSettings.AtPointHeightTolerance, UpVector))
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
		if ((Result == EBasicPathfindingResult::AccuratePath) ||
			(Result == EBasicPathfindingResult::InaccuratePath))
			MoveToComp.ReportNewPath();
		else if (Result == EBasicPathfindingResult::BadStart)
			MoveToComp.ReportFailed(EPathfollowingMoveToFailReason::BadStart);
		else if (Result == EBasicPathfindingResult::BadDestination)
			MoveToComp.ReportFailed(EPathfollowingMoveToFailReason::BadDestination);
		else if (Result == EBasicPathfindingResult::NoPath)
			MoveToComp.ReportFailed(EPathfollowingMoveToFailReason::NoPath);
	}

	void DebugDrawPath(FVector Start, FVector Destination, bool bDrawAccuratePath)
	{
#if EDITOR
		//WallclimbingComp.Navigation.bDebugDrawPathfinding = true;
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (!Owner.bHazeEditorOnlyDebugBool && !WallclimbingComp.Navigation.bDebugDrawPathfinding)
			return;

		WallclimbingComp.bDebug = WallclimbingComp.Navigation.bDebugDrawPathfinding;
		
		Debug::DrawDebugSphere(Start, 10, 4, (MoveToComp.CurrentStatus == EPathfollowingMoveToStatus::CouldNotFindStart) ? FLinearColor::Red : FLinearColor::Green);
		Debug::DrawDebugSphere(Destination, 10, 4, (MoveToComp.CurrentStatus == EPathfollowingMoveToStatus::CouldNotFindEnd) ? FLinearColor::Red : FLinearColor::Green);

		const FVector DrawOffset = FVector(0.0, 0.0, 0.0);

		if (!MoveToComp.Path.IsValid())
		{
			Debug::DrawDebugLine(Start + DrawOffset, Destination + DrawOffset, FLinearColor::Red, 1.0, 0.0);
			return;
		}

		if (MoveToComp.Path.Points.Num() == 1)
			Debug::DrawDebugLine(Start + DrawOffset, MoveToComp.Path.Points[0] + DrawOffset, FLinearColor::Yellow, 0.0, 0.0);

		MoveToComp.Path.DrawDebug(DrawOffset, FLinearColor::Yellow);

		for (FWallClimbingPathNode Node :  WallclimbingComp.Path)
		{
			Debug::DrawDebugArrow(Node.Location, Node.Location + Node.Normal * 100.0, 10.0, FLinearColor::DPink, 1);
		}

		// if (WallclimbingComp.Path.Num() > 1)
		// {
		// 	FHazeRuntimeSpline Spline;
		// 	FWallClimbingPathNode PrevNode = WallclimbingComp.Path[0];
		// 	Spline.AddPointWithUpDirection(PrevNode.Location, PrevNode.Normal);
		// 	const float IntermediateDistance = 100.0;
		// 	for (int i = 1; i < WallclimbingComp.Path.Num(); i++)
		// 	{
		// 		const FWallClimbingPathNode& Node = WallclimbingComp.Path[i];
		// 		if (!PrevNode.Location.IsWithinDist(Node.Location, IntermediateDistance))
		// 		{
		// 			// Path stretch leading up to current node is rather long, add intermediate node
		// 			Spline.AddPointWithUpDirection(PrevNode.Location + (Node.Location - PrevNode.Location).GetSafeNormal() * IntermediateDistance, PrevNode.Normal);
		// 		}

		// 		// Add location for current node
		// 		Spline.AddPointWithUpDirection(Node.Location, Node.Normal);
		// 		PrevNode = Node;
		// 	}

		// 	int nPoints = 100;
		// 	TArray<FVector> SplineLocs;
		// 	Spline.GetLocations(SplineLocs, nPoints);
		// 	TArray<FRotator> SplineRots;
		// 	Spline.GetRotations(SplineRots, nPoints);
		// 	for (int i = 1; i < SplineLocs.Num(); i++)
		// 	{
		// 		Debug::DrawDebugLine(SplineLocs[i-1], SplineLocs[i], FLinearColor::Purple);
		// 		if ((i % 2) == 1)
		// 			Debug::DrawDebugLine(SplineLocs[i-1], SplineLocs[i-1] + SplineRots[i - 1].UpVector * 30.0, FLinearColor::DPink);
		// 	}
		// }

#endif		
	}
}

