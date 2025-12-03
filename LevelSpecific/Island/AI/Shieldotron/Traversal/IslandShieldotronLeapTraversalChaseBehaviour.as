class UIslandShieldotronLeapTraversalChaseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(n"TraversalChase");

	UHazeActorRespawnableComponent RespawnComp;
	UTrajectoryTraversalComponent TraversalComp;
	UIslandShieldotronJumpComponent JumpComp;
	UIslandForceFieldComponent ForceFieldComp;
	UIslandShieldotronSettings Settings;

	UTrajectoryTraversalScenepoint LaunchPoint;
	int Destination;
	FTraversalTrajectory TraversalTrajectory;
	bool bTraversing;

	AAIIslandShieldotron ShieldotronOwner;

	UIslandShieldotronAggressiveTeam AggressiveTeam;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShieldotronOwner = Cast<AAIIslandShieldotron>(Owner);
		TraversalComp = UTrajectoryTraversalComponent::Get(Owner);
		JumpComp = UIslandShieldotronJumpComponent::Get(Owner);
		ForceFieldComp = UIslandForceFieldComponent::GetOrCreate(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
		AggressiveTeam = Cast<UIslandShieldotronAggressiveTeam>(HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam));
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		if (LaunchPoint != nullptr && LaunchPoint.IsUsing(Owner))
		{
			LaunchPoint.Release(Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TraversalComp.CurrentArea == nullptr)
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.ChaseActivationMinRange))
			return false;
		// Only aggressive team will activate chase behaviour.
		UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam);		
		if (Team == nullptr)
			return false;
		if (!Team.IsMember(Owner))
			return false;

		if (AggressiveTeam != nullptr)
		{
			TArray<AHazeActor> Members = AggressiveTeam.GetMembers();
			for (AHazeActor Member : Members)
			{
				if (Member == Owner)
					continue;

				if (AggressiveTeam.IsOtherTeamMemberChasingTarget(TargetComp.Target, Owner))
					return false;
			}

			if (IsCrowdingTargets())
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > 5.0) // failsafe if we get stuck
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bTraversing = false;
		LaunchPoint = nullptr;
		
		// Update Aggressive team blackboard on both sides.
		if (AggressiveTeam == nullptr)
			AggressiveTeam = Cast<UIslandShieldotronAggressiveTeam>(HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam));

		if(!AggressiveTeam.TryReportChasing(TargetComp.Target, Owner))
		{
			DeactivateBehaviour();
			return;
		}

		// Only run pathfind checks on control side.
		if (!HasControl())
			return;


		// Skip traverse if we're already in the same navmesh area as target 
		// Since it's expensive we don't test this in ShouldActivate
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (Pathfinding::HasPath(Owner.ActorLocation, TargetLoc) && Math::Abs(TargetLoc.Z - Owner.ActorLocation.Z) < 200) 
			return;		

		// If the Player is currently off the navmesh we need to guess the closest area.		
		// Heuristic: assume that the closest scenepoint is also on the closest navmesh area.
		// Problem: Can be spaces where the closest scenepoint is on a navmesh area with different elevation.
		//	Try to find on matching elevation first
		// 		Subproblem: Player can be elevated right next to the closest navmesh area.
		// New heuristic: Find the closest navmesh point first and try to find closest scenepoint from there.
		

		ATraversalAreaActorBase TargetsCurrentArea;
		TryGetTargetsCachedCurrentArea(TargetsCurrentArea);

		// temp debug draws
		// if (TargetComp.Target == Game::Mio)
		// 	Debug::DrawDebugSphere(SearchLocation, 50, 12, FLinearColor::Red, 2.0, 2.0);
		// else
		// 	Debug::DrawDebugSphere(SearchLocation, 50, 12, FLinearColor::Blue, 2.0, 2.0);
		// Debug::DrawDebugSphere(TargetsClosestScenepoint.WorldLocation, Duration = 2.0);
		// Debug::DrawDebugSphere(TargetsCurrentArea.ActorCenterLocation, Duration = 2.0);
		// Debug::DrawDebugSphere(TraversalComp.CurrentArea.ActorCenterLocation, 50, LineColor = FLinearColor::Green, Duration = 2.0);

		CheckAndUpdateCurrentArea(); // Update because might have fallen down and current area is out of date.
		if (TargetsCurrentArea == TraversalComp.CurrentArea)
			return;

		float BestDistSqr = BIG_NUMBER;
		TArray<UTraversalScenepointComponent> TraversalPoints;
		TraversalComp.CurrentArea.GetAllMethodsTraversalPoints(TraversalComp.Methods, TraversalPoints);
		for (UTraversalScenepointComponent Pt : TraversalPoints)
		{
			UTrajectoryTraversalScenepoint Point = Cast<UTrajectoryTraversalScenepoint>(Pt);
			if (Point == nullptr)
				continue;
			
			if (!Point.CanUse(Owner)) // CanUse includes checking cooldown
				continue;

			float OwnerToPointSqrDistance = Owner.ActorLocation.DistSquared2D(Point.WorldLocation);

			for (int iDest = 0; iDest < Point.GetDestinationCount(); iDest++)
			{
				// Skip Transit Areas for now				
				ATraversalAreaActorBase DestArea = Cast<ATraversalAreaActorBase>(Point.GetDestinationArea(iDest));
				if ((DestArea == nullptr) || DestArea.bTransitArea)
					continue;

				// Shortest path is considered good point.
				FVector DestLoc = Point.GetDestination(iDest);
				FVector DestToTarget = TargetLoc - DestLoc;
				float DestToTargetSqrDist = DestToTarget.SizeSquared2D();
				float TotalSqrDist = (DestToTargetSqrDist * 1.5) + OwnerToPointSqrDistance; // Weighted SizeSquare2D. More important to pick a close point than landing close to player.

				// Heuristic weight. Trying to match target's area. However, sometimes the target may not be in an adjacent area.
				if (TargetsCurrentArea != DestArea)
					TotalSqrDist *= 2;

				// Good destination!
				if (TotalSqrDist < BestDistSqr)
				{
					// Skip if it means taking a jerky turn at launch point.
					//FVector ToPointDir = (Point.WorldLocation - Owner.ActorLocation).GetSafeNormal2D();
					// FVector ToDestDir = (DestLoc - Point.WorldLocation).GetSafeNormal2D();
					// if (Math::Abs(ToDestDir.DotProduct(ToPointDir)) < Math::Cos(Math::DegreesToRadians(20))) // Take abs, since owner can be behind or in front of launch point
					// 	TotalSqrDist *= 2;

					LaunchPoint = Point;
					Destination = iDest;
					BestDistSqr = TotalSqrDist;	
				}
			}
		}
		
		if (LaunchPoint != nullptr)
		{			
			CrumbSetLaunchPoint(LaunchPoint);
		}
	}

	// Check if we have fallen off area and update current area accordingly
	void CheckAndUpdateCurrentArea()
	{		
		if (LaunchPoint == nullptr || !Pathfinding::HasPath(Owner.ActorLocation, LaunchPoint.WorldLocation)) // if we can't find a path to the currently selected launchpoint
		{
			// Find current area
			UTraversalManager Manager = Traversal::GetManager();
			UScenepointComponent Scenepoint = Manager.FindClosestTraversalScenepointOnSameElevation(Owner.ActorLocation);
			if (Scenepoint != nullptr)
			{
				ATraversalAreaActorBase Area = Manager.GetCachedScenepointArea(Scenepoint);
				TraversalComp.SetCurrentArea(Area); // needn't be synced
				if (LaunchPoint == nullptr)
					return;
				
				CrumbReleaseLaunchPoint();
				DeactivateBehaviour(); // Try again.
			}
		}
	}

	void TryGetTargetsCachedCurrentArea(ATraversalAreaActorBase&out OutTargetsCurrentArea)
	{
		FPlayerTraversalAreaInfo TargetAreaInfo = IslandShieldotron::Team::GetPlayerLastKnownAreaInfo(TargetComp.Target);
		if (TargetAreaInfo.bIsSet && Time::GameTimeSeconds - TargetAreaInfo.LastTraversalAreaUpdate < 0.25)
		{
			// if we have updated the known area recently, use that
			OutTargetsCurrentArea = TargetAreaInfo.LastKnownTraversalArea;
		}
		else
		{
			// if area information is outdated, update
			FVector SearchLocation; // Location from which to find the closest scenepoint
			FVector TargetsNavmeshLocation;
			if (Pathfinding::FindNavmeshLocation(TargetComp.Target.ActorLocation, 500, 200, TargetsNavmeshLocation))
				SearchLocation = TargetsNavmeshLocation;
			else
				SearchLocation = TargetComp.Target.ActorLocation;

			UTraversalManager TraversalManager = Traversal::GetManager();
			UScenepointComponent TargetsClosestScenepoint = TraversalManager.FindClosestTraversalScenepointOnSameElevation(SearchLocation);
			if (TargetsClosestScenepoint == nullptr)
				TargetsClosestScenepoint = TraversalManager.FindClosestTraversalScenepoint(SearchLocation);
			if (TargetsClosestScenepoint == nullptr)
				return; // This shouldn't be possible though.
			
			OutTargetsCurrentArea = TraversalManager.GetCachedScenepointArea(TargetsClosestScenepoint);
			IslandShieldotron::Team::SetPlayersLastKnownArea(TargetComp.Target, OutTargetsCurrentArea);			
		}		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (LaunchPoint != nullptr && LaunchPoint.IsUsing(Owner))
		{
			LaunchPoint.CooldownDuration = 5.0; // temp
			LaunchPoint.Release(Owner);			
		}
		AggressiveTeam.ReportStopChasing(TargetComp.Target, Owner);
		if (JumpComp.bIsJumping)
		{
			if (!JumpComp.bIsLanding)
			{
				// Was interrupted before triggering landing. Stunned.
				JumpComp.bIsJumping = false;
			}
		}
		if (Owner.IsCapabilityTagBlocked(n"Stunned"))
			Owner.UnblockCapabilities(n"Stunned", this); // Let jump finish before being stunned.

		UHazeTeam EvasiveTeam = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronEvasiveTeam);
		if (EvasiveTeam == nullptr)
			Cooldown.Set(1.0);
	}

	float DelayTimer = 0;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (LaunchPoint == nullptr)
		{
			// Try again later
 			Cooldown.Set(1.0);
			return;			
		}
		if (DelayTimer > 0)
		{
			DelayTimer -= DeltaTime;
			return;
		}		

		DestinationComp.RotateTowards(TargetComp.Target);

		// Have we reached point to launch away from yet?
		if (!bTraversing && LaunchPoint.IsAt(Owner))
		{
			bTraversing = true;
			JumpComp.bIsJumping = true;
			if (HasControl())
				Owner.BlockCapabilities(n"Stunned", this); // Let jump finish before being stunned.
			if (LaunchPoint.WorldLocation.Z < TraversalTrajectory.LandLocation.Z)
			{
				AnimComp.RequestFeature(FeatureTagIslandSecurityMech::JumpUp , EBasicBehaviourPriority::Medium, this);
				DelayTimer = 0.23;
			}
			else
			{
				AnimComp.RequestFeature(FeatureTagIslandSecurityMech::JumpDown , EBasicBehaviourPriority::Medium, this);
			}
		}
		else if (!bTraversing)
		{
			// Still moving to point from which we launch traversal
			DestinationComp.MoveTowardsIgnorePathfinding(LaunchPoint.WorldLocation, Settings.ChaseMoveSpeed);
			//Debug::DrawDebugSphere(LaunchPoint.WorldLocation, 50, 12, Duration = 2);
			AnimComp.RequestFeature(AnimComp.BaseMovementTag, EBasicBehaviourPriority::Low, this);
		}
		else if (!TraversalComp.IsAtDestination(TraversalTrajectory.LandLocation))
		{
			// Traversing to destination
			TraversalComp.Traverse(TraversalTrajectory);
		}
		else
		{
			// We're there!
			if (HasControl())
			{
				ATraversalAreaActorBase DestinationArea = Cast<ATraversalAreaActorBase>(LaunchPoint.GetDestinationArea(Destination));
				TraversalComp.SetCurrentArea(DestinationArea); // needn't be synced. Only used by control side.
				Owner.UnblockCapabilities(n"Stunned", this); // Let jump finish before being stunned.
			}			
			JumpComp.bIsLanding = true;

			Cooldown.Set(0.05);
		}
	}
	
	UFUNCTION(CrumbFunction)
	void CrumbSetLaunchPoint(UTrajectoryTraversalScenepoint Point)
	{
		LaunchPoint = Point;
		LaunchPoint.Use(Owner); // This needs to be crumbed in order to keep track of which points are available for claiming on remote side.
		LaunchPoint.GetTraversalTrajectory(Destination, TraversalTrajectory); // Necessary to crumb for triggering jump animation on remote
	}

	// This needs to be crumbed in order to keep track of which points are available for claiming on remote side.
	UFUNCTION(CrumbFunction)
	void CrumbReleaseLaunchPoint()
	{
		LaunchPoint.Release(Owner);
		LaunchPoint = nullptr;
	}

	bool IsCrowdingTargets() const
	{
		TArray<AHazeActor> Members = AggressiveTeam.GetMembers();
		for (AHazeActor Member : Members)
		{
			if (Member == Owner)
				continue;

			if (!AggressiveTeam.IsOtherTeamMemberChasingAnyPlayer(Owner))
				return false;
			
			float SquareCloseDist = 500 * 500;
			if (Member.GetSquaredDistanceTo(Owner) < SquareCloseDist && Game::Mio.GetSquaredDistanceTo(Game::Zoe) < SquareCloseDist)
				return true;
		}

		return false;
	}
}