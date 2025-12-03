class UEnforcerGrenadeAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default CapabilityTags.Add(n"EnforcerWeaponGrenade");
	default CapabilityTags.Add(n"Attack");

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UEnforcerGrenadeLauncherComponent Launcher;
	UBasicAIHealthComponent HealthComp;
	USkylineEnforcerAnimationComponent EnforcerAnimComp;
	UEnforcerGrenadeSettings Settings;
	
	FBasicAIAnimationActionDurations Durations;

	AHazePlayerCharacter Target;
	TPerPlayer<UTargetTrailComponent> TrailComps;
	TPerPlayer<UHazeMovementComponent> MoveComps;
	UGentlemanComponent GentlemanComp;
	bool bWieldedGrenade = false;
	bool bLaunchedGrenade = false;
	AEnforcerGrenade Grenade;

	AHazePlayerCharacter NotMovingPlayerTarget = nullptr;
	FVector NotMovingLoc;
	float NotMovingDuration = 0.0;
	FVector LastTargetGroundLoc;

	const FName UseGrenadeToken = n"UseGrenadeToken";
	const FName FirstSpottedByGrenadeUserTag = n"FirstSpottedByGrenadeUserTag";
	const FName LastSpottedByGrenadeUserTag = n"LastSpottedByGrenadeUserTag";

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		Launcher = UEnforcerGrenadeLauncherComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		EnforcerAnimComp = USkylineEnforcerAnimationComponent::Get(Owner);
		Settings = UEnforcerGrenadeSettings::GetSettings(Owner);		

		TrailComps[EHazePlayer::Mio] = UTargetTrailComponent::GetOrCreate(Game::Mio);
		TrailComps[EHazePlayer::Zoe] = UTargetTrailComponent::GetOrCreate(Game::Zoe);
		MoveComps[EHazePlayer::Mio] = UHazeMovementComponent::Get(Game::Mio);
		MoveComps[EHazePlayer::Zoe] = UHazeMovementComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Queue managment
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);

		// Keep track of when combat started, i.e. when current target was first spotted
		if (TargetComp.HasValidTarget() && HealthComp.IsAlive())
		{
			// Was target spotted before?
			if (GetCombatDuration() == 0.0) 
				TargetComp.GentlemanComponent.ReportAction(FirstSpottedByGrenadeUserTag);
			TargetComp.GentlemanComponent.ReportAction(LastSpottedByGrenadeUserTag);
		}

		if (Settings.PlayerNotMovingDuration > 0.0)
		{
			// Track if player remains near one place for an extended time
			if (TargetComp.Target != NotMovingPlayerTarget)
			{
				// New target
				NotMovingDuration = 0.0;
				NotMovingPlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
				if (NotMovingPlayerTarget != nullptr)
				{
					// Update not moving duration from trail
					FVector TargetLoc = NotMovingPlayerTarget.ActorLocation;
					const float Interval = 0.2;
					for (float Fraction = Interval; Fraction < 1.001; Fraction += Interval)
					{
						float Age = Fraction * Settings.PlayerNotMovingDuration;
						FVector TrailLoc = TrailComps[NotMovingPlayerTarget].GetTrailLocation(Age);
						if (!TrailLoc.IsWithinDist(TargetLoc, Settings.PlayerNotMovingRadius))	
							break;
						NotMovingDuration = Age;
						NotMovingLoc = TrailLoc;
					}					
				}
			} 
			else if (NotMovingPlayerTarget != nullptr)
			{
				// Update from current position
				FVector TargetLoc = NotMovingPlayerTarget.ActorLocation;
				if (TargetLoc.IsWithinDist(NotMovingLoc, Settings.PlayerNotMovingRadius))
				{
					// Still not moving far enough
					NotMovingDuration += DeltaTime;
				}	
				else
				{
					// Target moved
					NotMovingDuration = 0.0;
					NotMovingLoc = TargetLoc;
				}
			}
		}
	}

	float GetCombatDuration() const
	{
		if (Time::GetGameTimeSince(TargetComp.GentlemanComponent.GetLastActionTime(LastSpottedByGrenadeUserTag)) > 5.0)
			return 0.0; // Combat is over

		float CombatStartTime = TargetComp.GentlemanComponent.GetLastActionTime(FirstSpottedByGrenadeUserTag);
		if (CombatStartTime == 0.0)
			return 0.0; // Combat has not started yet

		return Time::GetGameTimeSince(CombatStartTime);				
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MinRange))
			return false;
		if (!TargetComp.HasVisibleTarget(TargetOffset = FVector(0.0, 0.0, -50.0)))
			return false;
		if (GetCombatDuration() < Settings.InitialPause)
			return false;
		if (!TargetComp.GentlemanComponent.CanClaimToken(UseGrenadeToken, this))
			return false;
		if (NotMovingDuration < Settings.PlayerNotMovingDuration)
			return false;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (MoveComps[Player].IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (Settings.GentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.GentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		

		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		GentlemanComp = TargetComp.GentlemanComponent;
		LastTargetGroundLoc = Target.ActorLocation;

		GentCostComp.ClaimToken(this, Settings.GentlemanCost);
		GentlemanComp.ClaimToken(UseGrenadeToken, this);

		Durations.Telegraph = Settings.TelegraphDuration;
		Durations.Anticipation = Settings.AnticipationDuration;
		Durations.Action = Settings.ActionDuration;
		Durations.Recovery = Settings.RecoveryDuration;
		EnforcerAnimComp.FinalizeDurations(LocomotionFeatureAISkylineTags::EnforcerShooting, SubTagAIEnforcerShooting::ThrowGrenade, Durations);
		//AnimComp.RequestAction(LocomotionFeatureAISkylineTags::EnforcerShooting, SubTagAIEnforcerShooting::ThrowGrenade, EBasicBehaviourPriority::Medium, this, Durations);
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::EnforcerShooting, SubTagAIEnforcerShooting::ThrowGrenade, EBasicBehaviourPriority::Medium, this, Durations.GetTotal());

		bLaunchedGrenade = false;
		bWieldedGrenade = false;
		
		// Spawn grenade and hide it until it's time to wield it
		UBasicAIProjectileComponent Projectile = Launcher.Launch(FVector::ZeroVector);
		Grenade = Cast<AEnforcerGrenade>(Projectile.Owner);
		Grenade.AddActorVisualsBlock(this);
		Grenade.AddActorTickBlock(this);

		UEnforcerEffectHandler::Trigger_OnTelegraphThrowGrenade(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this);
		GentlemanComp.ReleaseToken(UseGrenadeToken, this, Settings.GlobalMinInterval);

		// Can't do this with deactivation params, since capability is most often deactivated from compound (when taking damage)
		if (HasControl() && bWieldedGrenade && !bLaunchedGrenade)
			CrumbDropGrenade();

		UEnforcerEffectHandler::Trigger_OnPostGrenadeThrown(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bLaunchedGrenade && !MoveComps[Target].IsInAir())
			LastTargetGroundLoc = GetTargetLocation();

		if (!bWieldedGrenade && Durations.IsInAnticipationRange(ActiveDuration))
			WieldGrenade();

		if (!bLaunchedGrenade && Durations.IsInActionRange(ActiveDuration) && HasControl())
			CrumbThrowGrenade(LastTargetGroundLoc);

		DestinationComp.RotateTowards(Target);
	}

	FVector GetTargetLocation()
	{
		FVector PredictedLocation = Target.ActorLocation + TrailComps[Target].GetAverageVelocity(0.5) * Settings.TargetPredictionDuration;
		FVector ViewOffset = Target.ViewRotation.Vector().VectorPlaneProject(Target.ActorUpVector).GetSafeNormal() * Settings.BlastRadius * 0.5;
		FVector Loc = PredictedLocation + ViewOffset;		
		if (Owner.ActorLocation.IsWithinDist(Loc, Settings.MinRange))
			return Owner.ActorLocation + (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal(0.1, Owner.ActorForwardVector) * Math::Min(Settings.MinRange, Settings.BlastRadius + 50.0);
		return Loc;
	}

	void WieldGrenade()
	{
		bWieldedGrenade = true;
		Grenade.RemoveActorVisualsBlock(this);
		Grenade.Wield(Launcher);
		UEnforcerEffectHandler::Trigger_OnWieldGrenade(Owner, FEnforcerEffectOnThrowGrenadeData(Grenade));
	}

	UFUNCTION(CrumbFunction)
	void CrumbThrowGrenade(FVector TargetLoc)
	{
		if (!bWieldedGrenade)
			WieldGrenade();

		bLaunchedGrenade = true;	
		Grenade.RemoveActorTickBlock(this);

		FVector LaunchLoc = Grenade.ActorLocation;
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(LaunchLoc, TargetLoc, Settings.Gravity, Settings.ThrowSpeed);
		Grenade.ProjectileComp.Gravity = Settings.Gravity;
		Grenade.Throw(Owner, LaunchVelocity);

		UEnforcerEffectHandler::Trigger_OnThrowGrenade(Owner, FEnforcerEffectOnThrowGrenadeData(Grenade));
	}

	UFUNCTION(CrumbFunction)
	void CrumbDropGrenade()
	{
		if (!bWieldedGrenade)
			WieldGrenade();

		bLaunchedGrenade = true;	
		Grenade.RemoveActorTickBlock(this);
		Grenade.ProjectileComp.Gravity = Settings.Gravity;
		Grenade.Throw(Owner, FVector::ZeroVector);
	}
} 