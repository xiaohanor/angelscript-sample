
class UIslandShieldotronGroundPathfollowingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Pathfinding");
	default CapabilityTags.Add(n"GroundPathfinding");

	// This should run between anything setting destination and movement capability 
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPathfollowingMoveToComponent MoveToComp;
	UIslandJetpackShieldotronComponent JetpackComp;
	UPathfollowingSettings Settings;
	UGroundPathfollowingSettings GroundSettings;
	FVector OwnPrevLoc;
	FVector PrevDestination;
	bool bAccuratePath = false;
	float InaccurateRetryTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveToComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		JetpackComp = UIslandJetpackShieldotronComponent::Get(Owner);		
		Settings = UPathfollowingSettings::GetSettings(Owner);
		GroundSettings = UGroundPathfollowingSettings::GetSettings(Owner);
	}	

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		MoveToComp.Path.Reset();
		MoveToComp.PathIndex = -1;
		OwnPrevLoc = Owner.ActorLocation;
		PrevDestination = OwnPrevLoc;
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
		if (JetpackComp.GetCurrentFlyState() != EIslandJetpackShieldotronFlyState::IsGrounded)
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
		if (JetpackComp.GetCurrentFlyState() == EIslandJetpackShieldotronFlyState::IsAirBorne)
			return false;
		return false;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated()
    {
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.ApplySettings(BasicAICharacterGroundPathfollowingSettings, this);
		Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector Destination = MoveToComp.FinalDestination;
		if (NeedsNewPath())
		{
			EBasicPathfindingResult Result = FindPath(OwnLoc, Destination, MoveToComp.PathIndex);
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

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			DebugDrawPath(OwnLoc, Destination, bAccuratePath);
#endif		
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
		// ProjectPointToNavigation is rather crappy, we first need to check vertical, then full size to get suitable locations
		FVector VerticalProjectionRange = FVector(4.0, 4.0, GroundSettings.NavmeshMaxProjectionHeight);
		FVector ProjectionRange = FVector(Settings.NavmeshMaxProjectionRange, Settings.NavmeshMaxProjectionRange, GroundSettings.NavmeshMaxProjectionHeight);
		FVector PathStart;
		if (!UNavigationSystemV1::ProjectPointToNavigation(Start, PathStart, nullptr, nullptr, VerticalProjectionRange))
			if (!UNavigationSystemV1::ProjectPointToNavigation(Start, PathStart, nullptr, nullptr, ProjectionRange))
				return EBasicPathfindingResult::BadStart;

		FVector PathDest;
		if (!UNavigationSystemV1::ProjectPointToNavigation(Destination, PathDest, nullptr, nullptr, VerticalProjectionRange))
			if (!UNavigationSystemV1::ProjectPointToNavigation(Destination, PathDest, nullptr, nullptr, ProjectionRange))
				return EBasicPathfindingResult::BadDestination;

		MoveToComp.Path.SetFromNavmeshPath(UNavigationSystemV1::FindPathToLocationSynchronously(PathStart, PathDest));
		if (!MoveToComp.Path.IsValid())
			return EBasicPathfindingResult::NoPath;
		
		// We have a new path to follow
		OutPathIndex = 1;

		// Is destination outside navmesh?
		if (!MoveToComp.Path.Points.Last().IsWithinDist(Destination, Settings.OutsideNavmeshEndRange))
			return EBasicPathfindingResult::InaccuratePath;

		// Are we starting outside navmesh?
		if (!MoveToComp.Path.Points[0].IsWithinDist(Start, Settings.OutsideNavmeshStartRange))
			return EBasicPathfindingResult::InaccuratePath;

		// Path is good
		return EBasicPathfindingResult::AccuratePath;
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
		if (Pathfinding::IsPathNear(OwnLoc, PathLoc, Range, GroundSettings.AtPointHeightTolerance))
			return true;

		// Check for overshoot
		FVector PrevTo = PathLoc - OwnPrevLoc;
		FVector CurTo = PathLoc - OwnLoc;
		if (PrevTo.DotProduct(CurTo) < 0.0)
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
		const FVector DrawOffset = FVector(0.0, 0.0, 20.0);

		if (MoveToComp.Path.Points.Num() < 2)
		{
			Debug::DrawDebugLine(Start + DrawOffset, Destination + DrawOffset, FLinearColor::Red, 0.0, 5.0);
			return;
		}

		FVector PrevLoc = MoveToComp.Path.Points[0];
		for (int i = 1; i < MoveToComp.Path.Points.Num(); i++)
		{
			FVector Loc = MoveToComp.Path.Points[i];
			FLinearColor Color = (i < MoveToComp.PathIndex) ? FLinearColor::Green : (bDrawAccuratePath ? FLinearColor::LucBlue : FLinearColor::Yellow);
			Debug::DrawDebugLine(PrevLoc + DrawOffset, Loc + DrawOffset, Color, 0.0, 5.0);
			PrevLoc = Loc;
		}

		// System::DrawDebugLine(Start + DrawOffset, MoveToComp.FinalDestination + DrawOffset, FLinearColor::White, 0.0, 0.5);
		// for (FVector PointLoc : MoveToComp.Path.Points) {System::DrawDebugLine(PointLoc, PointLoc + DrawOffset * 10.0, FLinearColor::Yellow, 0.0, 2.0);}
		// for (FVector PointLoc : MoveToComp.Path.Points) {System::DrawDebugLine(PointLoc, Start, FLinearColor::Red, 0.0, 2.0);}
	}
}

