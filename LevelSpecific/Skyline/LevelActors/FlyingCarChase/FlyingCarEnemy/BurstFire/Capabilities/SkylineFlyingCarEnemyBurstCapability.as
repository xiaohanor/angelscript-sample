class USkylineFlyingCarEnemyBurstFireCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBasicAIProjectileLauncherComponent LauncherComp;
	UBasicAIProjectileLauncherComponent RightLauncherComp;
	USkylineFlyingCarEnemyTrackingLaserComponent TrackingLaserComp;

	FBasicBehaviourCooldown Cooldown;

	UBasicAIHealthComponent HealthComp;

	USkylineFlyingCarEnemyShipSettings Settings;

	private float FiredTime = 0.0;
	private int FiredProjectiles = 0;
	private const float TargetInvisibleTimeLimit = 1.0;

	private bool bUseLeftLauncherNext = false;

	ASkylineFlyingCarEnemyShip AttackShip;
	FHazeAcceleratedVector AccLaserEndLocation;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		//
		AttackShip = Cast<ASkylineFlyingCarEnemyShip>(Owner);
		LauncherComp = AttackShip.LeftCannonProjectileLauncherComponent; // Using the launcher specific to ship.
		RightLauncherComp = AttackShip.RightCannonProjectileLauncherComponent; // Adding a second launcher
		TrackingLaserComp = USkylineFlyingCarEnemyTrackingLaserComponent::Get(Owner);
		
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		Settings = USkylineFlyingCarEnemyShipSettings::GetSettings(Owner);
	}
	
	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!HasValidTarget())
			return false;		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!WantsToAttack())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		// Note that we deactivate whenever cooldown is set, not when !Cooldown.IsOver
		if (Cooldown.IsSet())
			return true; 
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Cooldown.Reset();
		FiredProjectiles = 0;
//
		TrackingLaserComp.TrackingLaserParams.LaserStartLocation =  AttackShip.LaserPivot.WorldLocation;
		TrackingLaserComp.TrackingLaserParams.LaserEndLocation = AttackShip.LaserPivot.WorldLocation;
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(LauncherComp, Settings.TelegraphLaserTrackingDuration));
		AccLaserEndLocation.SnapTo(LauncherComp.WorldLocation + LauncherComp.ForwardVector * Settings.TrackingLaserRange);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bHasStartedTelegraphing = false;
		bHasStoppedTelegraphing = false;
		bHasStartedLaunchTelegraphing = false;
		USkylineFlyingCarEnemyAttackShipEffectHandler::Trigger_OnStopTelegraphing(Owner);
	}

	bool bHasStartedTelegraphing = false;
	bool bHasStoppedTelegraphing = false;
	bool bHasStartedLaunchTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHasStartedTelegraphing)
		{
			bHasStartedTelegraphing = true;
			USkylineFlyingCarEnemyAttackShipEffectHandler::Trigger_OnStartTelegraphingTrackingLaser(Owner, FSkylineFlyingCarEnemyBurstFireTelegraphingParams(LauncherComp.WorldLocation, RightLauncherComp.WorldLocation, Owner.ActorLocation, TrackingLaserComp, LauncherComp, RightLauncherComp));
		}

		if(ActiveDuration < Settings.TelegraphLaserTrackingDuration)
		{
			// LaserTrace
			FHitResult Hit;
			FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PhysicsBody);
			Trace.UseLine();			
			Hit = Trace.QueryTraceSingle(LauncherComp.WorldLocation, LauncherComp.WorldLocation + LauncherComp.ForwardVector * Settings.TrackingLaserRange);
			if (Hit.bBlockingHit)
			{
				AccLaserEndLocation.SnapTo(Hit.ImpactPoint);
			}
			else
			{
				AccLaserEndLocation.AccelerateTo(LauncherComp.WorldLocation + LauncherComp.ForwardVector * Settings.TrackingLaserRange, 0.5, DeltaTime);
			}
			TrackingLaserComp.TrackingLaserParams.LaserEndLocation = AccLaserEndLocation.Value;

			TrackingLaserComp.TrackingLaserParams.LaserStartLocation = AttackShip.LaserPivot.WorldLocation;
			if (ActiveDuration > (Settings.TelegraphLaserTrackingDuration - Settings.TelegraphLaunchDuration) && !bHasStartedLaunchTelegraphing)
			{
				USkylineFlyingCarEnemyAttackShipEffectHandler::Trigger_OnStartTelegraphing(Owner, FSkylineFlyingCarEnemyBurstFireTelegraphingParams(LauncherComp.WorldLocation, RightLauncherComp.WorldLocation, Owner.ActorLocation, TrackingLaserComp, LauncherComp, RightLauncherComp));
				bHasStartedLaunchTelegraphing = true;
			}
			return;
		}
		if (!bHasStoppedTelegraphing)
		{
			bHasStoppedTelegraphing = true;
			USkylineFlyingCarEnemyAttackShipEffectHandler::Trigger_OnStopTelegraphing(Owner);
		}


			// Fire multiple shots within one frame if necessary.
			while (FiredProjectiles < Settings.BurstProjectileAmount && Time::GetGameTimeSince(FiredTime) > Settings.TimeBetweenBurstProjectiles)
			{
				FireProjectile();
			}
	
		
		if (FiredProjectiles >= Settings.BurstProjectileAmount)
		{
			Cooldown.Set(Settings.BurstLaunchInterval - ActiveDuration);
		}
	}
	
	private void FireProjectile()
	{		
		// Aim forward
		FVector AimDir = LauncherComp.ForwardVector;
		UBasicAIProjectileLauncherComponent CurrentLauncher = bUseLeftLauncherNext ? LauncherComp : RightLauncherComp;
		bUseLeftLauncherNext = !bUseLeftLauncherNext;

		UBasicAIProjectileComponent ProjectileComp = CurrentLauncher.Launch(AimDir * Settings.LaunchSpeed);		
		ASkylineFlyingCarEnemyBurstProjectile BurstProjectile = Cast<ASkylineFlyingCarEnemyBurstProjectile>(ProjectileComp.Owner);
		if (BurstProjectile != nullptr)
			BurstProjectile.InitSettings();

		if (FiredProjectiles > 0)
			FiredTime += Settings.TimeBetweenBurstProjectiles;
		else
			FiredTime = Time::GameTimeSeconds;
		FiredProjectiles++;

		USkylineFlyingCarEnemyBurstFireProjectileEventHandler::Trigger_OnLaunch(ProjectileComp.HazeOwner);
		USkylineFlyingCarEnemyBurstFireProjectileEventHandler::Trigger_OnLaunch(Owner);
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(CurrentLauncher, FiredProjectiles, Settings.BurstProjectileAmount));		
	}

	bool HasValidTarget() const
	{
		if (AttackShip.FollowTarget == nullptr)
			return false;

		if (AttackShip.FollowTarget.GetDistanceTo(Owner) > Settings.MaxAttackRange)
			return false;
		
		if (AttackShip.FollowTarget.GetDistanceTo(Owner) < Settings.MinAttackRange)
			return false;

		return true;
	}
}

