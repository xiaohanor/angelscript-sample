class USkylineFlyingCarEnemyFireTurretCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(SkylineFlyingCarEnemy::Turret::SkylineCarEnemyTurretFireTag);
	default CapabilityTags.Add(SkylineFlyingCarEnemy::Turret::SkylineCarEnemyTurretTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineFlyingCarEnemy FlyingCarEnemy;
	USkylineFlyingCarEnemyTurretComponent TurretComp;
	UBasicAIHealthComponent HealthComp;
	float InitialCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingCarEnemy = Cast<ASkylineFlyingCarEnemy>(Owner);
		TurretComp = USkylineFlyingCarEnemyTurretComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		InitialCooldown = Math::RandRange(0, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;
		
		if (!HasValidTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TurretComp.bIsFiring = true;
		TurretComp.LastFireTime = Time::GameTimeSeconds - TurretComp.FireInterval + InitialCooldown;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TurretComp.bIsFiring = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		MoveMuzzles();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (FlyingCarEnemy.FollowTarget != nullptr)
			TryFire();
	}

	void TryFire()
	{
		while(TurretComp.TimeSinceLastFire() > TurretComp.FireInterval)
		{
			if(TurretComp.IsMagazineEmpty())
				break;

			const FVector Start = TurretComp.GetCurrentMuzzleLocation();

			FPlane TargetPlane = FPlane(TurretComp.GetTargetLocation(), FlyingCarEnemy.FollowTarget.ActorUpVector);

			FVector End = TargetPlane.RayPlaneIntersection(Start, TurretComp.GetCurrentMuzzle().ForwardVector);

			FVector Recoil = TurretComp.GetRecoilOffset();

			End += Recoil;

			const FVector FireDirection = (End - Start).GetSafeNormal();

			Fire(Start, FireDirection);

			TurretComp.LastFireTime += TurretComp.FireInterval;
		}
	}

	void Fire(FVector Start, FVector Direction)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.IgnoreActor(Owner);
		Trace.UseLine();

		FVector End = Start + Direction * TurretComp.Range;

		FHitResult HitResult = Trace.QueryTraceSingle(Start, End);

		if(HitResult.bBlockingHit)
		{
			USkylineFlyingCarHealthComponent FCHealthComp = USkylineFlyingCarHealthComponent::Get(HitResult.Actor);
			if (FCHealthComp != nullptr)
			{
				FSkylineFlyingCarDamage Damage;
				Damage.Amount =  TurretComp.PlayerDamage;

				//Temp for dmg effect
				//Game::Mio.DamagePlayerHealth(TurretComp.PlayerDamage);
				//Game::Zoe.DamagePlayerHealth(TurretComp.PlayerDamage);


				FCHealthComp.TakeDamage(Damage);
			}
		}

		TurretComp.ConsumeBullet();

		FSkylineFlyingCarEnemyTurretFireEventData FireEventData;
		FireEventData.MuzzleComp = TurretComp.GetCurrentMuzzle();
		FireEventData.StartLocation = Start;
		FireEventData.StartRotation = FireEventData.MuzzleComp.WorldRotation;
		FireEventData.EndLocation = HitResult.IsValidBlockingHit() ? HitResult.ImpactPoint : HitResult.TraceEnd;
		USkylineFlyingCarEnemyTurretEventHandler::Trigger_OnFire(FlyingCarEnemy, FireEventData);

		if(HitResult.IsValidBlockingHit())
		{
			FSkylineFlyingCarEnemyTurretHitEventData HitEventData;
			HitEventData.MuzzleComp = TurretComp.GetCurrentMuzzle();
			HitEventData.StartLocation = Start;
			HitEventData.StartRotation = HitEventData.MuzzleComp.WorldRotation;
			HitEventData.HitResult = HitResult;
			USkylineFlyingCarEnemyTurretEventHandler::Trigger_OnHit(FlyingCarEnemy, HitEventData);
		}

		TurretComp.GetCurrentMuzzle().LastFireTime = Time::GameTimeSeconds;
		TurretComp.CurrentMuzzleIndex = (TurretComp.CurrentMuzzleIndex + 1) % TurretComp.MuzzleComponents.Num();
	}

	void MoveMuzzles()
	{
		for(auto MuzzleComp : TurretComp.MuzzleComponents)
		{
			if(MuzzleComp.LastFireTime > 0)
			{
				float TimeSinceFire = Time::GetGameTimeSince(MuzzleComp.LastFireTime);
				float RecoilAlpha = SkylineFlyingCarEnemyTurretMuzzleRecoilCurve.GetFloatValue(TimeSinceFire / MuzzleComp.RecoilDuration);
				check(RecoilAlpha == Math::Saturate(RecoilAlpha));
				MuzzleComp.SetRelativeLocation(MuzzleComp.InitialRelativeLocation + FVector(MuzzleComp.RecoilDelta * RecoilAlpha, 0, 0));
			}
		}
	}

	bool HasValidTarget() const
	{
		if (FlyingCarEnemy.FollowTarget == nullptr)
			return false;

		if (FlyingCarEnemy.FollowTarget.GetDistanceTo(Owner) > SkylineFlyingCarEnemy::Turret::Range)
			return false;

		return true;
	}
};