class USummitSmashapultLobProjectileBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(BasicAITags::Attack);

	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	FBasicAIAnimationActionDurations Durations;
	UHazeSkeletalMeshComponentBase Mesh;
	UBasicAINetworkedProjectileLauncherComponent Lobber;
	ASummitSmashapultGlob Glob = nullptr;
	USummitSmashapultSettings Settings;
	UTargetTrailComponent TrailComp;
	UGentlemanComponent GentlemanComponent;
	USummitSmashapultComponent PultComp;

	bool bHasLaunched = false;
	bool bHasProjectileExpired = false;

	const FName LobToken = n"SmashapultLobGlob";

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
		Lobber = UBasicAINetworkedProjectileLauncherComponent::Get(Owner);
		PultComp = USummitSmashapultComponent::GetOrCreate(Owner); 
		Settings = USummitSmashapultSettings::GetSettings(Owner);
		GentlemanComponent = UGentlemanComponent::GetOrCreate(Game::Zoe);
		GentlemanComponent.SetMaxAllowedClaimants(LobToken, Settings.LobProjectileGlobalAllowance);

		// Prepare lobber projectiles so they're available on both sides in network before first activation.
		Lobber.PrepareProjectiles(1); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (PultComp.PeaceKeepers.Num() > 0)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.LobProjectileRange))
			return false;	
		float ToTargetYaw = (TargetComp.Target.ActorLocation - Owner.ActorLocation).Rotation().Yaw;
		if (!Math::IsNearlyZero(FRotator::NormalizeAxis(Owner.ActorRotation.Yaw - ToTargetYaw), Settings.LobProjectileMaxYaw))
			return false;	
		if (!GentlemanComponent.CanClaimToken(LobToken, this))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentlemanComponent.ClaimToken(LobToken, this);
		
		Durations.Telegraph = Math::Min(Settings.LobProjectilePrimeDelay * 2.0, Settings.LobProjectileLaunchDelay - 0.3);
		Durations.Anticipation = Settings.LobProjectileLaunchDelay - Durations.Telegraph - 0.1;
		Durations.Action = 0.2;
		Durations.Recovery = 2.0;
		AnimComp.RequestAction(SummitSmasherFeatureTag::Attack, EBasicBehaviourPriority::Medium, this, Durations);

		Glob = nullptr;
		bHasLaunched = false;
		bHasProjectileExpired = false;

		TrailComp = UTargetTrailComponent::GetOrCreate(TargetComp.Target);

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Lobber, Settings.LobProjectileLaunchDelay));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if ((ActiveDuration > Durations.GetTotal()) && bHasProjectileExpired)
			return true; // Done with anim and projectile has exploded

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentlemanComponent.ReleaseToken(LobToken, this, Settings.LobProjectileInterval * 0.5);
		if (Glob != nullptr)
			Glob.RespawnComp.OnUnspawn.UnbindObject(this);
		Glob = nullptr;
		Cooldown.Set(Settings.LobProjectileInterval);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Glob == nullptr)
		{
			if (ActiveDuration > Settings.LobProjectilePrimeDelay)
			{
				// Prime projectile (show it attached to hand)
				UBasicAIProjectileComponent Projectile = Lobber.Launch(FVector::ZeroVector);
				Glob = Cast<ASummitSmashapultGlob>(Projectile.Owner); 
				Glob.AttachToComponent(Mesh, n"Attach", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
				Glob.RespawnComp.OnUnspawn.AddUFunction(this, n"OnProjectileUnspawned");
				Glob.PrimeGlob();
			}
			return;
		} 

		if (!bHasLaunched && (ActiveDuration > Settings.LobProjectileLaunchDelay))
		{
			bHasLaunched = true;
			Glob.DetachFromActor();
			FVector LaunchLoc = Glob.ActorLocation;
			FVector TargetLoc = TargetComp.Target.ActorLocation;

			FVector ProjectileDestination = TargetLoc;
			FVector PredictionVelocity = TrailComp.GetAverageVelocity(0.2);
			USummitTeenDragonRollingLiftComponent LiftComp = USummitTeenDragonRollingLiftComponent::GetOrCreate(TargetComp.Target);
			if (LiftComp.CurrentSpline != nullptr)
			{
				// Spline locked, aim at location ahead along spline from where we should be in a few seconds
				FSplinePosition SplinePos = LiftComp.CurrentSpline.GetClosestSplinePositionToWorldLocation(TargetComp.Target.ActorLocation);

				float SpeedAlongSpline = SplinePos.WorldForwardVector.DotProduct(PredictionVelocity);
				if (SpeedAlongSpline < 0.0)
					SpeedAlongSpline = 0.0; // Always aim ahead in spline direction

				// Move the set lead time and some distance ahead where the projectile will be in blast range but not auto-detonate.
				// Note that we ignore estimated air time, static lead time will be more predictable to player.
				float LeadDistance = SpeedAlongSpline * Settings.LobProjectileLeadTime + 1.0; // The 1.0 extra so we won't end up behind
				LeadDistance += Math::Min(Settings.ProjectileBlastRadius, Settings.ProjectileBlastRadius * Settings.ProjectileDetonationFraction + 200.0);
				SplinePos.Move(LeadDistance);

				// Spline is usually some ways above actual movement surface, project down
				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
				Trace.IgnorePlayers();
				if (LiftComp.CurrentRollingLift != nullptr)
					Trace.IgnoreActor(LiftComp.CurrentRollingLift);
				Trace.UseLine();
				FVector Offset = FVector(0.0, 0.0, 2000.0); // Spline is quite far away sometimes :/

				// Run a few attempts further up the spline in case we are at a gap
				ProjectileDestination = SplinePos.WorldLocation - Offset; // Backup destination
				for (int i = 0; i < 3; i++)
				{
					FHitResult Hit = Trace.QueryTraceSingle(SplinePos.WorldLocation + Offset * 0.1, SplinePos.WorldLocation - Offset);
					if (Hit.bBlockingHit)
					{
						// Found ground!
						ProjectileDestination = Hit.ImpactPoint;
						break;
					}

					// No ground, try again 
					SplinePos.Move(800.0);
				}
			}
			else
			{
				// Not on spline, just roughly predict where ball should be in a while
				ProjectileDestination = TargetLoc + PredictionVelocity * Settings.LobProjectileLeadTime;
			}

			Trajectory::FOutCalculateVelocity VelocityParams = Trajectory::CalculateParamsForPathWithHeight(LaunchLoc, ProjectileDestination, Settings.ProjectileGravity, Settings.ProjectileTrajectoryHeight, 100000.0);
			FVector LaunchVelocity = VelocityParams.Velocity;
			Glob.LobGlob(LaunchVelocity);

			UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Lobber, 1, 1));
		}
	}

	UFUNCTION()
	private void OnProjectileUnspawned(AHazeActor RespawnableActor)
	{
		bHasProjectileExpired = true;
		if (Glob != nullptr)
			Glob.RespawnComp.OnUnspawn.UnbindObject(this);
		Glob = nullptr; // This can now be reused, so don't hang on to it.
	}
}
