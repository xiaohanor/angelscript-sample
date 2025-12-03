struct FSummitCritterSwarmGrabBallParams
{
	ASummitRollingLift Ball;
}

class USummitCritterSwarmGrabBallBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCritterSwarmSettings Settings;

	UBasicAIHealthComponent HealthComp;
	USummitCritterSwarmComponent SwarmComp;

	float InViewDuration = 0.0;
	int iCritter = 0;
	float NextGrabTime = 0.0;
	ASummitRollingLift Ball;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitCritterSwarmSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner); 
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive() || !HealthComp.IsAlive() || IsBlocked() || !TargetComp.HasValidTarget())
		{
			InViewDuration = 0.0;
			return;
		}

		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.GrabBallRange))
		{
			InViewDuration = 0.0;
			return;
		}

		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (!SceneView::IsInView(PlayerTarget, Owner.ActorLocation))
		{
			InViewDuration = 0.0;
			return;
		}
		
		InViewDuration += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitCritterSwarmGrabBallParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if(InViewDuration < Settings.GrabBallInViewDuration)
			return false;
		USummitTeenDragonRollingLiftComponent LiftComp = USummitTeenDragonRollingLiftComponent::Get(Game::Zoe);
		if (LiftComp == nullptr)
			return false;
		if (LiftComp.CurrentRollingLift == nullptr)
			return false;	
		OutParams.Ball = LiftComp.CurrentRollingLift;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitCritterSwarmGrabBallParams Params)
	{
		Super::OnActivated();
		iCritter = 0;
		NextGrabTime = 0.0;
		Ball = Params.Ball;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		for (USummitSwarmingCritterComponent Critter : SwarmComp.Critters)
		{
			Critter.ClearExternalTarget();
		}

		Ball.AccelerationFactor.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move straight towards target until touching.
		// Separate critters will disengage from swarm and latch onto ball (locally simulated)
		FVector FromTarget = (Owner.ActorCenterLocation - TargetComp.Target.ActorCenterLocation).GetSafeNormal2D();
		FVector Dest = TargetComp.Target.ActorCenterLocation + FromTarget * (SwarmComp.BoundsRadius + 200.0);
		DestinationComp.MoveTowardsIgnorePathfinding(Dest, Settings.GrabBallSpeed * 0.5);

		if ((ActiveDuration > NextGrabTime) && SwarmComp.Critters.IsValidIndex(iCritter))
		{
			// Set target for critter
			USummitSwarmingCritterComponent Critter = SwarmComp.Critters[iCritter];
			FVector GrabOffset = Critter.Offset.GetSafeNormal() * Ball.CollisionSphere.SphereRadius;
			GrabOffset.Z = 400.0; 
			Critter.SetExternalTarget(Ball.CollisionSphere, GrabOffset, Settings.GrabBallSpeed);
			iCritter++;
			NextGrabTime += 0.1;
		}

		// Slowdown of ball from grabbers
		int NumGrabbers = SwarmComp.GetNumberOfGrabbingCritters();
		if (NumGrabbers > 0)
		{
			float Hindrance = Settings.GrabbedBallHindranceFactor;
			float FullGrab = Settings.NumCritters * 0.25;
			if (NumGrabbers < FullGrab)
				Hindrance *= 0.25 + 0.75 * (float(NumGrabbers) / FullGrab);
			Ball.AccelerationFactor.Apply(1.0 - Hindrance, this, EInstigatePriority::Normal);
		}

		// Abort from damage as long as only a few critters are grabbing
		if ((NumGrabbers < SwarmComp.Critters.Num() * Settings.GrabBallAbortFraction) && (Time::GetGameTimeSince(HealthComp.LastDamageTime) < 0.5))
			Cooldown.Set(Settings.GrabBallAbortCooldown);

	}
}

