class UIslandPunchotronLeapTraversalChaseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UHazeActorRespawnableComponent RespawnComp;
	UTrajectoryTraversalComponent TraversalComp;
	UBasicAITraversalSettings TraversalSettings;
	UIslandPunchotronSettings Settings;

	UTrajectoryTraversalScenepoint LaunchPoint;
	int Destination;
	FTraversalTrajectory TraversalTrajectory;
	EIslandPunchotronSidescrollerLeapState LeapState;
	bool bTraversing;
	bool bHasLanded = false;
	bool bHasStartedBreaking = false;
	float LandedDelayTimer;
	float LaunchDelayTimer;
	float TraversedDuration = 0.0;

	AAIIslandPunchotronSidescroller Punchotron;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		TraversalComp = UTrajectoryTraversalComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		Punchotron = Cast<AAIIslandPunchotronSidescroller>(Owner);
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
#if EDITOR
		if (Cast<AAIIslandPunchotronSidescroller>(Owner).bIsJumpDisabled)
			return false;
#endif		
		if (!TargetComp.HasValidTarget())
			return false;
		if ( Math::Abs(TargetComp.Target.ActorLocation.Z - Owner.ActorLocation.Z) < 200)
			return false;
		if (TraversalComp.CurrentArea == nullptr)
			return false;
		if (TraversalComp.CurrentArea.bTransitArea)
			return true; // Always chase out of a transit area
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, TraversalSettings.ChaseMinRange * 0.05))
			return false;
		if (ActivationDelay > 0.0)
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
	void OnActivated()
	{
		Super::OnActivated();
		LeapState = EIslandPunchotronSidescrollerLeapState::MovingToLaunchPoint;
		bTraversing = false;
		bHasLanded = false;
		bHasStartedBreaking = false;
		LaunchPoint = nullptr;
		TraversedDuration = 0.0;

		if (!HasControl())
			return;


		// Skip traverse if we're already in the same navmesh area as target 
		// Since it's expensive we don't test this in ShouldActivate
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (Pathfinding::HasPath(Owner.ActorLocation, TargetLoc) && Math::Abs(TargetLoc.Z - Owner.ActorLocation.Z) < 200) 
			return;

		UpdateTargetsCachedCurrentArea();
		CheckAndUpdateOwnersCurrentArea();

		// Skip if in the same area
		if (TargetsLastKnownTraversalArea.LastKnownTraversalArea == TraversalComp.CurrentArea)
			return;


		FVector ToTargetX = TargetLoc - Owner.ActorLocation;
		ToTargetX = FVector(ToTargetX.X, 0, 0);
		
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
			
			if (Math::Abs(Point.WorldLocation.Z - Owner.ActorLocation.Z) > 100)
				continue;


			// Shortest path is considered good point.
			float OwnerToPointSqrDistance = Owner.ActorLocation.DistSquared(Point.WorldLocation);

			if (OwnerToPointSqrDistance < BestDistSqr)
			{
				// Good launchpoint!
				LaunchPoint = Point;
				BestDistSqr = OwnerToPointSqrDistance;
			}
			else
			{
				continue;
			}

			// Find best destination spot... maybe should pick random for variation instead.
			float BestDestDistSqr = BIG_NUMBER;
			for (int iDest = 0; iDest < Point.GetDestinationCount(); iDest++)
			{
                // Shortest path is considered good point.
                FVector DestLoc = Point.GetDestination(iDest);
                FVector DestToTarget = TargetLoc - DestLoc;
                float DestToTargetSqrDist = DestToTarget.SizeSquared();
				
				// Good destination?
				if (DestToTargetSqrDist < BestDestDistSqr)
				{
					Destination = iDest;
					BestDestDistSqr = DestToTargetSqrDist;
				}
			}
		}
		if (LaunchPoint != nullptr)
		{
			CrumbSetLaunchPoint(LaunchPoint);
		}

		LandedDelayTimer = 0.75;
		UIslandSidescrollerGroundMovementSettings::SetUseConstrainVolume(Owner, false, this, EHazeSettingsPriority::Final);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandPunchotronSettings::ClearSidescrollerGroundFriction(Owner, this);
		if (LaunchPoint != nullptr && LaunchPoint.IsUsing(Owner))
		{
			LaunchPoint.CooldownDuration = 5.0; // temp
			LaunchPoint.Release(Owner);			
		}
		if (Owner.IsCapabilityTagBlocked(n"Stunned"))
			Owner.UnblockCapabilities(n"Stunned", this); // Let jump finish before being stunned.

		UIslandSidescrollerGroundMovementSettings::ClearUseConstrainVolume(Owner, this, EHazeSettingsPriority::Final);
	}

	float ActivationDelay = 0.25;
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (TargetComp.HasValidTarget() && Math::Abs(TargetComp.Target.ActorLocation.Z - Owner.ActorLocation.Z) > 100)
			ActivationDelay -= DeltaTime;
		else
			ActivationDelay = 0.25;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (LaunchPoint == nullptr)
		{
			// Try again later
 			Cooldown.Set(0.1);
			return;			
		}

		if (bHasLanded)
		{
			if (!bHasStartedBreaking)
			{
				UIslandPunchotronSettings::SetSidescrollerGroundFriction(Owner, Settings.SidescrollerGroundFriction * 3.0, this);
				bHasStartedBreaking = true;
			}
			LandedDelayTimer -= DeltaTime;			
			if (LandedDelayTimer < 0.0)
				Cooldown.Set(1.0);
			return;
		}

		if (LeapState == EIslandPunchotronSidescrollerLeapState::DelayingLaunch)
		{
			if (LaunchDelayTimer > 0)
			{
				AnimComp.RequestFeature(FeatureTagIslandPunchotron::JumpStart , EBasicBehaviourPriority::Medium, this);
				UIslandPunchotronEffectHandler::Trigger_OnJump(Owner);
				LaunchDelayTimer -= DeltaTime;
				return;
			}
			else
			{
				SetLeapState(EIslandPunchotronSidescrollerLeapState::Traversing);
				UIslandPunchotronSettings::ClearSidescrollerGroundFriction(Owner, this);
				if (HasControl())
				{
					CrumbStartTraversal();
				}
				else
				{
					// Immmediately set locally on remote.
					bTraversing = true;
					TraversalComp.Traverse(TraversalTrajectory);
				}
			}
		}

		// Cancel jump if target leaves the destination area or has same area as owner
		if (!bTraversing)
		{
			UpdateTargetsCachedCurrentArea();
			CheckAndUpdateOwnersCurrentArea();
			if (LaunchPoint == nullptr)
			{
				Cooldown.Set(0.1);
				return;
			}
			if (TraversalComp.CurrentArea == TargetsLastKnownTraversalArea.LastKnownTraversalArea)
			{
				Cooldown.Set(0.1);
				return;
			}
			ATraversalAreaActorBase DestinationArea = Cast<ATraversalAreaActorBase>(LaunchPoint.GetDestinationArea(Destination));
			if (DestinationArea != TargetsLastKnownTraversalArea.LastKnownTraversalArea)
			{
				Cooldown.Set(0.1);
				return;
			}
		}


		DestinationComp.RotateTowards(TargetComp.Target);

		// Have we reached point to launch away from yet?
		if (LeapState == EIslandPunchotronSidescrollerLeapState::MovingToLaunchPoint && IsAt2D(Owner, LaunchPoint.WorldLocation, 40, DeltaTime))
		{
			SetLeapState(EIslandPunchotronSidescrollerLeapState::DelayingLaunch);
			UIslandPunchotronSettings::SetSidescrollerGroundFriction(Owner, Settings.SidescrollerGroundFriction * 3.0, this);
			LaunchDelayTimer = 0.13;
			AnimComp.RequestFeature(FeatureTagIslandPunchotron::JumpStart , EBasicBehaviourPriority::Medium, this);
			UIslandPunchotronEffectHandler::Trigger_OnJump(Owner);

			if (HasControl())
				Owner.BlockCapabilities(n"Stunned", this); // Let jump finish before being stunned.
		}

		if (!bTraversing)
		{
			// Still moving to point from which we launch traversal
			DestinationComp.MoveTowardsIgnorePathfinding(LaunchPoint.WorldLocation, BasicSettings.ChaseMoveSpeed);
			AnimComp.RequestFeature(AnimComp.BaseMovementTag, EBasicBehaviourPriority::Low, this);
		}
		else if (!TraversalComp.IsAtDestination(TraversalTrajectory.LandLocation))
		{			
			// Traversing to destination
			TraversalComp.Traverse(TraversalTrajectory);
			
			// Approximate the remaining trajectory travel time, the exact time is handled by the IslandSidescrollerLeapTraversalMovementCapability.
			const float TrajectoryTotalDuration = TraversalTrajectory.GetTotalTime();
			TraversedDuration += DeltaTime;
			if (TraversedDuration < TrajectoryTotalDuration - 0.25)// temp hack before adjusting animations and ABP
			{
				AnimComp.RequestFeature(FeatureTagIslandPunchotron::FallStart , EBasicBehaviourPriority::Medium, this); // Continue requesting tag to prevent landing animation from starting.
				UIslandPunchotronEffectHandler::Trigger_OnJump(Owner);
			} 
			else
				AnimComp.ClearFeature(this); // Start transitioning into landing animation.
		}
		else
		{
			// We're there!
			ATraversalAreaActorBase DestinationArea = Cast<ATraversalAreaActorBase>(LaunchPoint.GetDestinationArea(Destination));
			TraversalComp.SetCurrentArea(DestinationArea);
			bHasLanded = true;
			AnimComp.ClearFeature(this);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartTraversal()
	{
		bTraversing = true;
		TraversalComp.Traverse(TraversalTrajectory);
	}
	
	bool IsAt2D(AHazeActor Actor, FVector LaunchPointLocation, float Radius, float PredictTime = 0.0) const
	{
		if (Actor == nullptr)
			return false;
		
		FVector ActorLocation2D = Actor.ActorLocation;
		ActorLocation2D.Y = 0;
		FVector LaunchPointLocation2D = LaunchPointLocation;
		LaunchPointLocation2D.Y = 0;

		if (ActorLocation2D.DistSquared(LaunchPointLocation2D) < Math::Square(Radius))
			return true;

		if (PredictTime != 0.0) // Allow checking for overshoot with negative prediction time
		{
			FVector DeltaMove = Actor.GetActorVelocity() * PredictTime;
			FVector ToSP = LaunchPointLocation2D - ActorLocation2D;
			if (ToSP.DotProduct(DeltaMove) > 0.0)
			{	
				// We're moving towards sp
				FVector PredictedToSP = (LaunchPointLocation2D - (ActorLocation2D + DeltaMove));
				if (PredictedToSP.DotProduct(DeltaMove) < 0.0)	
				{
					// We will pass sp during predicted time
					return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetLaunchPoint(UTrajectoryTraversalScenepoint Point)
	{
		LaunchPoint = Point;
		LaunchPoint.Use(Owner); // This needs to be crumbed in order to keep track of which points are available for claiming on remote side.
		LaunchPoint.GetTraversalTrajectory(Destination, TraversalTrajectory); // Necessary to crumb for triggering jump animation on remote
	}

	FPlayerTraversalAreaInfo TargetsLastKnownTraversalArea;

	private void UpdateTargetsCachedCurrentArea()
	{
		if (!TargetsLastKnownTraversalArea.bIsSet || Time::GameTimeSeconds - TargetsLastKnownTraversalArea.LastTraversalAreaUpdate > 0.25)
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
			
			TargetsLastKnownTraversalArea.LastKnownTraversalArea = TraversalManager.GetCachedScenepointArea(TargetsClosestScenepoint);
			TargetsLastKnownTraversalArea.LastTraversalAreaUpdate = Time::GameTimeSeconds;
			TargetsLastKnownTraversalArea.bIsSet = true;	
		}
	}

	// Check if we have fallen off area and update current area accordingly
	void CheckAndUpdateOwnersCurrentArea()
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

	// This needs to be crumbed in order to keep track of which points are available for claiming on remote side.
	UFUNCTION(CrumbFunction)
	void CrumbReleaseLaunchPoint()
	{
		LaunchPoint.Release(Owner);
		LaunchPoint = nullptr;
	}

	void SetLeapState(EIslandPunchotronSidescrollerLeapState NewState)
	{
		check(LeapState != NewState);
		LeapState = NewState;
	}


}

enum EIslandPunchotronSidescrollerLeapState
{
	MovingToLaunchPoint,
	DelayingLaunch,
	Traversing,
	Landing,
	Landed,
	None
}