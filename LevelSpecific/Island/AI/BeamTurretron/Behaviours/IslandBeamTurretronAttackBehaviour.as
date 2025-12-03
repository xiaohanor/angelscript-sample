class UIslandBeamTurretronAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UGentlemanCostComponent GentCostComp;
	UBasicAIProjectileLauncherComponent LauncherComp;
	UIslandBeamTurretronTrackingLaserComponent TrackingLaserComp;

	USceneComponent CannonBase;
	FVector InitialCannonLocalLocation;
	FVector KickbackOffset;

	UBasicAIHealthComponent HealthComp;

	UIslandBeamTurretronSettings Settings;

	private float FiredTime = 0.0;
	private int FiredProjectiles = 0;
	private float ActivationDelayTime = 1.0;
	private float TargetInvisibleTimer = 0.0;
	private const float TargetInvisibleTimeLimit = 1.0;

	AAIIslandBeamTurretron BeamTurretron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		auto OwnerTurret = Cast<AAIIslandBeamTurretron>(Owner);
		LauncherComp = UBasicAIProjectileLauncherComponent::Get(Owner);
		TrackingLaserComp = UIslandBeamTurretronTrackingLaserComponent::Get(Owner);
		CannonBase = OwnerTurret.CannonPivot;
		InitialCannonLocalLocation = CannonBase.GetRelativeLocation();
		KickbackOffset = CannonBase.ForwardVector * -25.0;

		HealthComp = UBasicAIHealthComponent::Get(Owner);

		Settings = UIslandBeamTurretronSettings::GetSettings(Owner);

		AnimComp.bIsAiming = true;

		BeamTurretron = Cast<AAIIslandBeamTurretron>(Owner);
	}
	
	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MaxAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MinAttackRange))
			return false;
		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasGeometryVisibleTarget(TargetOffset = FVector(0,0, -79.0)))
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
		if(!GentCostComp.IsTokenAvailable(Settings.GentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (TargetInvisibleTimer > TargetInvisibleTimeLimit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		

		FiredProjectiles = 0;

		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.PlayAdditiveAnimation(FHazeAnimationDelegate(), ShootingFeature.SingleShot);

		GentCostComp.ClaimToken(this, Settings.GentlemanCost);
		TrackingLaserComp.TrackingLaserParams.LaserStartLocation = LauncherComp.WorldLocation;
		TrackingLaserComp.TrackingLaserParams.LaserEndLocation = LauncherComp.WorldLocation;
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(LauncherComp, Settings.TelegraphDuration));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		bHasStartedTelegraphing = false;
		bHasStoppedTelegraphing = false;
		bHasStartedLaunchTelegraphing = false;
		TargetInvisibleTimer = 0.0;
		UIslandBeamTurretronEffectHandler::Trigger_OnStopTelegraphing(Owner);
	}

	bool bHasStartedTelegraphing = false;
	bool bHasStoppedTelegraphing = false;
	bool bHasStartedLaunchTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < ActivationDelayTime)
		{
			return;
		}
		else if (!bHasStartedTelegraphing)
		{
			bHasStartedTelegraphing = true;
			UIslandBeamTurretronEffectHandler::Trigger_OnStartTelegraphingTrackingLaser(Owner, FIslandBeamTurretronTelegraphingParams(LauncherComp.WorldLocation, Owner.ActorLocation, TrackingLaserComp, LauncherComp));
		}

		// Check visibility
		if (!TargetComp.HasGeometryVisibleTarget(TargetOffset = FVector(0,0, -79.0)))
			TargetInvisibleTimer += DeltaTime;
		else
			TargetInvisibleTimer = 0.0;

		if(ActiveDuration < ActivationDelayTime + Settings.TelegraphDuration)
		{
			// LaserTrace
			TArray<EObjectTypeQuery> ObjectTypes;
			ObjectTypes.Add(EObjectTypeQuery::PhysicsBody); // Hit the player mesh
			ObjectTypes.Add(EObjectTypeQuery::WorldStatic); // Hit world geometry
			ObjectTypes.Add(EObjectTypeQuery::WorldDynamic); // Hit world geometry
			FHazeTraceSettings Trace = Trace::InitObjectTypes(ObjectTypes);
			Trace.UseLine();
			FHitResult Hit;
			Hit = Trace.QueryTraceSingle(LauncherComp.WorldLocation, LauncherComp.WorldLocation + LauncherComp.ForwardVector * Settings.TrackingLaserRange);
			if (Hit.bBlockingHit)
			{
				TrackingLaserComp.TrackingLaserParams.LaserEndLocation = Hit.ImpactPoint;
			}
			else
			{
				TrackingLaserComp.TrackingLaserParams.LaserEndLocation = LauncherComp.WorldLocation + LauncherComp.ForwardVector * Settings.TrackingLaserRange;
			}

			TrackingLaserComp.TrackingLaserParams.LaserStartLocation = LauncherComp.WorldLocation;
			if (ActiveDuration > (ActivationDelayTime + Settings.TelegraphDuration - Settings.TelegraphLaunchDuration) && !bHasStartedLaunchTelegraphing)
			{
				UIslandBeamTurretronEffectHandler::Trigger_OnStartTelegraphing(Owner, FIslandBeamTurretronTelegraphingParams(LauncherComp.WorldLocation, Owner.ActorLocation, TrackingLaserComp, LauncherComp));
				bHasStartedLaunchTelegraphing = true;
			}
			return;
		}
		if (!bHasStoppedTelegraphing)
		{
			bHasStoppedTelegraphing = true;
			UIslandBeamTurretronEffectHandler::Trigger_OnStopTelegraphing(Owner);
			KnockdownClosebyPlayer(); // Knockdown on first fired projectile.
		}


		// Fire and draft version of kickback
		if(HasControl() && FiredProjectiles < Settings.ProjectileAmount && (FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > Settings.TimeBetweenBurstProjectiles))
		{
			CrumbFireProjectile();
		}
		else if (FiredProjectiles == Settings.ProjectileAmount)
		{
			Cooldown.Set(Settings.LaunchInterval - ActiveDuration);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbFireProjectile()
	{		
		// Aim forward
		FVector AimDir = LauncherComp.ForwardVector;

		UBasicAIProjectileComponent ProjectileComp = LauncherComp.Launch(AimDir * Settings.LaunchSpeed);		
		
		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();

		UIslandBeamTurretronProjectileEventHandler::Trigger_OnLaunch(ProjectileComp.HazeOwner);
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(LauncherComp, FiredProjectiles, Settings.ProjectileAmount));		
	}

	private TPerPlayer<bool> HasHitPlayers;
	private void KnockdownClosebyPlayer()
	{		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			HasHitPlayers[Player] = false; // reset bool
			
			// Deal damage and apply knockdown
			if (IsPlayerCloseToMuzzles(Player))
			{
				HasHitPlayers[Player] = true;
				Player.DealTypedDamage(Owner, 0.9, EDamageEffectType::ProjectilesLarge, EDeathEffectType::ProjectilesLarge);

				FVector KnockdownDir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
				FKnockdown Knockdown;
				Knockdown.Duration = Settings.ProjectileKnockdownDuration;
				Knockdown.Move = KnockdownDir * 500;
				Player.ApplyKnockdown(Knockdown);
				Player.SetActorRotation((-Knockdown.Move).ToOrientationQuat());
			}
		}
	}

	private bool IsPlayerCloseToMuzzles(AHazePlayerCharacter Player)
	{
		float Dist = 250;
		const float DistSquared = Dist * Dist;
		FVector AimDir = LauncherComp.ForwardVector;

		if (LauncherComp.WorldLocation.DistSquared(Player.ActorCenterLocation) < DistSquared)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			Trace.IgnoreActor(Owner, true);			

			FHitResult Hit = Trace.QueryTraceSingle(BeamTurretron.ActorCenterLocation, LauncherComp.WorldLocation + AimDir * Dist);					
			AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
			if (HitPlayer == Player)
				return true;
		}

		return false;
	}
}

