class UIslandShieldotronLeapTraversalEvadeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(n"TraversalEvade");

	UHazeActorRespawnableComponent RespawnComp;
	UTrajectoryTraversalComponent TraversalComp;
	UIslandShieldotronJumpComponent JumpComp;
	UBasicAITraversalSettings TraversalSettings;
	UIslandShieldotronSettings Settings;

	UTrajectoryTraversalScenepoint LaunchPoint;
	int Destination;
	FTraversalTrajectory TraversalTrajectory;
	bool bTraversing;
	bool bShouldActivate = false;
	float LastCheckTime = 0.0;
	FVector EvadeLoc;	

	AAIIslandShieldotron ShieldotronOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShieldotronOwner = Cast<AAIIslandShieldotron>(Owner);
		TraversalComp = UTrajectoryTraversalComponent::Get(Owner);
		JumpComp = UIslandShieldotronJumpComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
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
		if (TraversalComp.CurrentArea == nullptr)
			return false;
		if (!bShouldActivate)
			return false;
		if (Owner.IsAnyCapabilityActive(n"MortarAttack"))
			return false;
		if (Owner.IsAnyCapabilityActive(n"RocketAttack"))
			return false;

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
	void PreTick(float DeltaTime)
	{
		if (IsActive())
			return;

		if (Owner.IsAnyCapabilityActive(n"MortarAttack"))
			return;

		if (Time::GetGameTimeSince(LastCheckTime) < 0.5)
			return;

		// TODO: replace individual check with team wide check for players' current areas.
		LastCheckTime = Time::GetGameTimeSeconds();
		bShouldActivate = false;

		// If there is an evasive team, only its members will activate the evasion behaviour
		UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronEvasiveTeam);		
		if (Team == nullptr)
			return;
		if (!Team.IsMember(Owner))
			return;

		// Evade closest player in the same area.
		AHazePlayerCharacter ClosestPlayer = Game::GetClosestPlayer(Owner.ActorLocation);
		if (!Owner.ActorLocation.IsWithinDist(ClosestPlayer.ActorLocation, Settings.EvadeActivationMinRange))
			return;

		if (Pathfinding::HasPath(Owner.ActorLocation, ClosestPlayer.ActorLocation))
		{
			EvadeLoc = ClosestPlayer.ActorLocation;
			bShouldActivate = true;
			return;
		}
		
		AHazeActor OtherPlayer = ClosestPlayer == Game::Mio ? Game::GetPlayer(EHazePlayer::Zoe) : Game::GetPlayer(EHazePlayer::Mio);
		if (!Owner.ActorLocation.IsWithinDist(OtherPlayer.ActorLocation, Settings.EvadeActivationMinRange))
			return;
		
		if (Pathfinding::HasPath(Owner.ActorLocation, OtherPlayer.ActorLocation))
		{
			EvadeLoc = OtherPlayer.ActorLocation;
			bShouldActivate = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bTraversing = false;
		bShouldActivate = false;
		
		if (!HasControl())
			return;

		LaunchPoint = nullptr;

		// Get list of all occupied areas to avoid		
		TArray<ATraversalAreaActorBase> FriendliesOccupiedAreas;
		GetFriendliesOccupiedAreas(FriendliesOccupiedAreas);
		TArray<ATraversalAreaActorBase> PlayersOccupiedAreas = IslandShieldotron::Team::GetPlayersLastKnownAreas();

		// Sort out good and bad candidates. Based on actor facing direction.		
		TArray<UTraversalScenepointComponent> TraversalPoints;
		TraversalComp.CurrentArea.GetAllMethodsTraversalPoints(TraversalComp.Methods, TraversalPoints);
		TArray<UTrajectoryTraversalScenepoint> GoodCandidates;
		TArray<UTrajectoryTraversalScenepoint> BadCandidates;
		for (UTraversalScenepointComponent Pt : TraversalPoints)
		{
			UTrajectoryTraversalScenepoint Point = Cast<UTrajectoryTraversalScenepoint>(Pt);
			if (Point == nullptr)
				continue;
			
			if (!Point.CanUse(Owner)) // CanUse includes checking cooldown
				continue;

			// Pick a point behind us.
			FVector ToPoint = Point.WorldLocation - Owner.ActorLocation;
			FVector ToEvadeLoc = EvadeLoc - Owner.ActorLocation;
			if (ToPoint.DotProduct(ToEvadeLoc) > 0)
			{
				BadCandidates.Add(Point);
				continue;
			}
			GoodCandidates.Add(Point);
		}

		// Try find a suitable point in front
		if (!TrySetLaunchPoint(GoodCandidates, FriendliesOccupiedAreas, PlayersOccupiedAreas))
		{
			// Try find a suitable point in back.
			if (!TrySetLaunchPoint(BadCandidates, FriendliesOccupiedAreas, PlayersOccupiedAreas))
			{
				// Else, take best good candidate.
				if (GoodCandidates.Num() > 0)
					TrySetLaunchPoint(GoodCandidates, TArray<ATraversalAreaActorBase>(), TArray<ATraversalAreaActorBase>());					
				else // Else, take best bad candidate.
					TrySetLaunchPoint(BadCandidates, TArray<ATraversalAreaActorBase>(), TArray<ATraversalAreaActorBase>());					
			}
		}
		
		// Find most remote destination available from this point
		if (LaunchPoint != nullptr)
		{
			float BestDestinationDistSqr = SMALL_NUMBER;  // Want to maximize this
			for (int iDest = 0; iDest < LaunchPoint.GetDestinationCount(); iDest++)
			{				
				FVector DestLoc = LaunchPoint.GetDestination(iDest);
				FVector DestToEvadeLoc = EvadeLoc - DestLoc; // Want to maximize this
				float DestToEvadeLocSqrDist = DestToEvadeLoc.SizeSquared();				
				ATraversalAreaActorBase DestArea = Cast<ATraversalAreaActorBase>(LaunchPoint.GetDestinationArea(iDest));
				if (DestArea == nullptr)
					continue;
				if (FriendliesOccupiedAreas.Contains(DestArea)) // skip occupied areas
					continue;
				if (PlayersOccupiedAreas.Contains(DestArea)) // skip occupied areas
					continue;

				// Good destination!
				if (DestToEvadeLocSqrDist > BestDestinationDistSqr)
				{
					Destination = iDest;
					BestDestinationDistSqr = DestToEvadeLocSqrDist;
				}

			}
		}

		if (LaunchPoint != nullptr)
		{
			CrumbSetLaunchPoint(LaunchPoint, Destination);
			// Check if we have fallen off area and update current area accordingly
			CheckAndUpdateCurrentArea();
		}
	}


	// Check if we have fallen off area and update current area accordingly
	void CheckAndUpdateCurrentArea()
	{		
		if (LaunchPoint == nullptr || !Pathfinding::HasPath(Owner.ActorLocation, LaunchPoint.WorldLocation))
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

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (LaunchPoint != nullptr && LaunchPoint.IsUsing(Owner))
		{
			LaunchPoint.CooldownDuration = 5.0; // temp
			LaunchPoint.Release(Owner);
		}
		if (JumpComp.bIsJumping)
		{
			if (!JumpComp.bIsLanding)
			{
				// Was interrupted before triggering landing. Stunned.
				JumpComp.bIsJumping = false;
			}
		}
		Cooldown.Set(2.0);
		if (Owner.IsCapabilityTagBlocked(n"Stunned"))
			Owner.UnblockCapabilities(n"Stunned", this); // Let jump finish before being stunned.
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
			DestinationComp.MoveTowardsIgnorePathfinding(LaunchPoint.WorldLocation, Settings.EvadeMoveSpeed);
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
	void CrumbSetLaunchPoint(UTrajectoryTraversalScenepoint Point, int _Destination)
	{
		LaunchPoint = Point;
		LaunchPoint.Use(Owner); // This needs to be crumbed in order to keep track of which points are available for claiming on remote side.
		LaunchPoint.GetTraversalTrajectory(_Destination, TraversalTrajectory); // Necessary to crumb for triggering jump animation on remote
	}

	// This needs to be crumbed in order to keep track of which points are available for claiming on remote side.
	UFUNCTION(CrumbFunction)
	void CrumbReleaseLaunchPoint()
	{
		LaunchPoint.Release(Owner);
		LaunchPoint = nullptr;
	}

	void GetFriendliesOccupiedAreas(TArray<ATraversalAreaActorBase>& OutFriendliesOccupiedAreas)
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronEvasiveTeam);
		for (AHazeActor Member : Team.GetMembers())
		{
			if (Member == Owner)
				continue;

			UTrajectoryTraversalComponent FellowTraversalComp = UTrajectoryTraversalComponent::Get(Member);
			ATraversalAreaActorBase CurrentArea = FellowTraversalComp.GetCurrentArea();
			if (CurrentArea != nullptr)
				OutFriendliesOccupiedAreas.AddUnique(CurrentArea);
		}
	}

	bool TrySetLaunchPoint(TArray<UTrajectoryTraversalScenepoint> Points, TArray<ATraversalAreaActorBase> FriendliesOccupiedAreas, TArray<ATraversalAreaActorBase> PlayersOccupiedAreas)
	{
		float BestDistSqr = BIG_NUMBER;		
		for (UTrajectoryTraversalScenepoint Point : Points)
		{
			float OwnerToPointSqrDistance = Owner.ActorLocation.DistSquared(Point.WorldLocation);
			if (OwnerToPointSqrDistance < BestDistSqr)
			{
				// Check that point leads to an unoccupied area
				for (int iDest = 0; iDest < Point.GetDestinationCount(); iDest++)
				{
					ATraversalAreaActorBase DestArea = Cast<ATraversalAreaActorBase>(Point.GetDestinationArea(iDest));
					bool bOccupiedByFriendly = FriendliesOccupiedAreas.Contains(DestArea);
					bool bOccupiedByPlayer = PlayersOccupiedAreas.Contains(DestArea);
					if (!bOccupiedByFriendly && !bOccupiedByPlayer)
					{
						// Area is clear
						LaunchPoint = Point;
						BestDistSqr = OwnerToPointSqrDistance;
						break;
					}
				}
			}
		}
		return LaunchPoint != nullptr;
	}
}