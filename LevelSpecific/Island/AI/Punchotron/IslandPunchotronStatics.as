namespace IslandPunchotron
{
	// Check whether move is possible, if not, do not activate
	bool CanPerformAttackMove(FVector ActorLocation, FVector TargetLocation, float TargetOffset, FVector& OutAttackMove, bool bIgnorePathfinding = false)
	{
		if (bIgnorePathfinding)
			return CanPerformAttackMoveIgnorePathfinding(ActorLocation, TargetLocation, TargetOffset, OutAttackMove);
		// Project target's location onto navmesh and use if found.
		FVector NavmeshLocation(0);
		if (Pathfinding::FindNavmeshLocation(TargetLocation, 10.0, 1000.0, NavmeshLocation))
		{
			FVector ToTargetNavmeshLoc = NavmeshLocation - ActorLocation;
			FVector ToTargetNavmeshLocDir = ToTargetNavmeshLoc.GetSafeNormal();
			OutAttackMove = ToTargetNavmeshLoc + ToTargetNavmeshLocDir * TargetOffset;

			// If we have not modified the destination with an offset, we're finished.
			if (TargetOffset < SMALL_NUMBER)
				return true;

			// Check whether halfway is above navmesh
			//FVector HalfwayLocation = Owner.ActorLocation + OutAttackMove * 0.5;
			//FVector HalfwayNavmeshLocation(0); // not used
			//if (!Pathfinding::FindNavmeshLocation(HalfwayLocation, 10.0, 1000.0, HalfwayNavmeshLocation))
			//	return false;
			
			//Do I have a navmesh under current Destination? If not, use the known location from under target, calculated above, instead of offset.
			FVector Destination = ActorLocation + OutAttackMove;
			FVector DestinationNavmeshLocation(0);
			if (Pathfinding::FindNavmeshLocation(Destination, 10.0, 500.0, DestinationNavmeshLocation))
				OutAttackMove = DestinationNavmeshLocation - ActorLocation;
			else
				OutAttackMove = NavmeshLocation - ActorLocation;

			return true;
		}
		
		return false;
	}

	// Trace for ground instead of navmesh
	bool CanPerformAttackMoveIgnorePathfinding(FVector ActorLocation, FVector TargetLocation, float TargetOffset, FVector& OutAttackMove)
	{		
		// Project target's location onto ground and use if found.
		FVector GroundLocation(0);
		if (GetGroundLocation(TargetLocation, 1000.0, GroundLocation))
		{
			FVector ToTargetGroundLoc = GroundLocation - ActorLocation;
			FVector ToTargetGroundLocDir = ToTargetGroundLoc.GetSafeNormal2D();
			OutAttackMove = ToTargetGroundLoc + ToTargetGroundLocDir * TargetOffset;
			
			// If we have not modified the destination with an offset, we're finished.
			if (TargetOffset < SMALL_NUMBER)
				return true;

			//Do I have a ground under current Destination? If not, use the known location from under target, calculated above, instead of offset.
			FVector Destination = ActorLocation + OutAttackMove;
			FVector DestinationGroundLocation(0);
			if (GetGroundLocation(Destination, 500.0, DestinationGroundLocation))
				OutAttackMove = DestinationGroundLocation - ActorLocation;
			else
				OutAttackMove = GroundLocation - ActorLocation;

			return true;
		}
		
		return false;
	}

	bool GetGroundLocation(FVector ActorLocation, float VerticalRange, FVector& OutGroundLocation)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
		Trace.UseLine();
		//Trace.IgnoreActor(Owner);

		FHitResult Obstruction = Trace.QueryTraceSingle(ActorLocation + FVector::UpVector * VerticalRange * 0.5, ActorLocation + FVector::DownVector * VerticalRange * 0.5);
		OutGroundLocation = Obstruction.ImpactPoint;
		return Obstruction.bBlockingHit;
	}

	bool IsOnGround(FVector ActorLocation, float VerticalRange, bool bIgnorePathfinding = false)
	{
		if (bIgnorePathfinding)
		{
			FVector OutGroundLocation;
			return GetGroundLocation(ActorLocation, VerticalRange, OutGroundLocation);
		}
		FVector NavmeshLocation;
		return Pathfinding::FindNavmeshLocation(ActorLocation, 10.0, VerticalRange, NavmeshLocation);
	}

	bool IsPlayerOnGround(AHazeActor Player)
	{
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
		return MoveComp.IsOnAnyGround();
	}
	
	bool HasTagTeamMember(AAIIslandPunchotron Owner)
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronTags::IslandPunchotronTeamTag);
		if (Team == nullptr)
			return false;
		TArray<AHazeActor> Members = Team.GetMembers();
		for (AHazeActor Member : Members)
		{
			if (Member == Owner) // Skip self
				continue;

			// Another punchotron targeting the same player?
			AAIIslandPunchotron PunchotronMember = Cast<AAIIslandPunchotron>(Member);
			if (PunchotronMember.TargetingComponent.Target == Owner.TargetingComponent.Target)
				return true;
		}
		return false;
	}

	bool IsPlayerDashing(AHazePlayerCharacter Player)
	{
		UPlayerStepDashComponent PlayerDashComp = UPlayerStepDashComponent::Get(Player);
		if (PlayerDashComp != nullptr && PlayerDashComp.IsDashing())
			return true;

		UPlayerAirDashComponent PlayerAirDashComp = UPlayerAirDashComponent::Get(Player);
		if (PlayerAirDashComp != nullptr && PlayerAirDashComp.IsAirDashing())
			return true;

		return false;
	}
}