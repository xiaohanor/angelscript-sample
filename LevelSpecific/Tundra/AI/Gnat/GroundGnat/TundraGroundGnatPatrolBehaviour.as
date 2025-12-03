class UTundraGroundGnatPatrolBehaviour : UBasicBehaviour
{
	// This decides if we're patrolling a Scenepoint or not, so needs some form of networking. For not make the behaviour crumbed.
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIHealthComponent HealthComp;
	bool bSearchForPatrolPoints = true;
	ATundraGroundGnatPatrolScenepointActor PatrolPoint;
	UTundraGnatSettings Settings;
	FVector Destination;
	float NewDestinationTime = 0.0;
	float AllowSwitchingTargetTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UTundraGnatSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnPostRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bSearchForPatrolPoints = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!bSearchForPatrolPoints)
			return;
		if (!Requirements.CanClaim(BehaviourComp, this))
			return; // Still doing entrance behaviours etc

		// Only search for patrol points once, after any higher prio behaviour has run it's course
		// We ignore patrol points if we enter them later
		bSearchForPatrolPoints = false;	
		TListedActors<ATundraGroundGnatPatrolScenepointActor> PatrolPoints;
		for (ATundraGroundGnatPatrolScenepointActor Point : PatrolPoints)
		{
			if (Point.IsAt(Owner))
			{
				PatrolPoint = Point;
				Destination = Owner.ActorLocation;
				return;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (PatrolPoint == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		// Don't patrol while target remains within scenepoint radius
		if (TargetComp.HasValidTarget() && PatrolPoint.IsAt(TargetComp.Target))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		// Stop patrolling and attack intruders when they enter aggro range (which should be a fraction of radius)
		if (TargetComp.HasValidTarget() && PatrolPoint.CanAggro(TargetComp.Target))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		// Ignore pathfinding once we've started patrolling; note that we do not clear this
		// as we assume any other behaviours will not need pathfinding either when we've begun
		// patrolling
		UPathfollowingSettings::SetIgnorePathfinding(Owner, true, this, EHazeSettingsPriority::Gameplay);

		NewDestinationTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PatrolPoint.Patrol(Owner);

		if (ActiveDuration > NewDestinationTime)
		{
			NewDestinationTime = ActiveDuration + Math::RandRange(1.0, 1.5) * Settings.PatrolSwitchDestinationInterval;
			Destination = PatrolPoint.GetScenepoint().WorldLocation + Math::GetRandomPointInCircle_XY() * PatrolPoint.GetScenepoint().Radius * 0.5;
		}

		if (ActiveDuration > Settings.PatrolStartPause)
		{
			Destination.Z = Owner.ActorLocation.Z;
			if (!Owner.ActorLocation.IsWithinDist(Destination, 100.0))
				DestinationComp.MoveTowards(Destination, Settings.PatrolMoveSpeed);
		}

		if (TargetComp.HasValidTarget())
		{
			if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.PatrolTrackTargetRange))
				DestinationComp.RotateTowards(TargetComp.Target);

			// Check if we should switch target
			if ((Time::GameTimeSeconds > AllowSwitchingTargetTime) && HasControl())
			{
				AHazePlayerCharacter OtherTarget = (TargetComp.Target == Game::Zoe) ? Game::Mio : Game::Zoe;
				if (TargetComp.IsValidTarget(OtherTarget) && PatrolPoint.CanAggro(OtherTarget))
				{
					// Target switching is internally networked
					AllowSwitchingTargetTime = Time::GameTimeSeconds + 8.0;				
					TargetComp.SetTarget(OtherTarget);	
				}
				else
				{
					AllowSwitchingTargetTime = Time::GameTimeSeconds + 2.0;				
				}
			}	
		}	
	}
}


