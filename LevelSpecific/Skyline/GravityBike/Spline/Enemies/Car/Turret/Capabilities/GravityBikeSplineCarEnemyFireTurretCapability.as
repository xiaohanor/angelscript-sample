class UGravityBikeSplineCarEnemyFireTurretCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBikeSpline::Enemy::EnemyFireTag);
	default CapabilityTags.Add(GravityBikeSpline::CarEnemy::Turret::CarEnemyTurretTag);
	default CapabilityTags.Add(GravityBikeSpline::CarEnemy::Turret::CarEnemyTurretFireTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineCarEnemy CarEnemy;
	UGravityBikeSplineCarEnemyTurretComponent TurretComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<AGravityBikeSplineCarEnemy>(Owner);
		TurretComp = UGravityBikeSplineCarEnemyTurretComponent::Get(Owner);
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;

		if(HealthComp.IsRespawning())
			return false;

		AGravityBikeSpline GravityBike = GravityBikeSpline::GetGravityBike();

		if(!GravityBike.BlockEnemyRifleFire.IsEmpty())
			return false;

		// Player is moving too slow, fire even if we have no instigators and are far away
		if(IsPlayerTooSlow())
		{
			if(Owner.ActorLocation.DistSquared(GravityBike.ActorLocation) < Math::Square(GravityBikeSpline::CarEnemy::Turret::MaxSlowTargetDistance))
				return true;
		}

		if(TurretComp.FireInstigators.Num() == 0)
			return false;

		// Target too far away
		if(Owner.ActorLocation.DistSquared(GravityBike.ActorLocation) > Math::Square(GravityBikeSpline::CarEnemy::Turret::MaxTargetDistance))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!GravityBikeSpline::GetGravityBike().BlockEnemyRifleFire.IsEmpty())
			return true;

		// Player is moving too slow, fire even if we have no instigators and are far away
		if(IsPlayerTooSlow())
		{
			if(Owner.ActorLocation.DistSquared(GravityBikeSpline::GetGravityBike().ActorLocation) < Math::Square(GravityBikeSpline::CarEnemy::Turret::MaxSlowTargetDistance))
				return false;
		}

		if(TurretComp.FireInstigators.Num() == 0)
			return true;

		// Target too far away
		if(Owner.ActorLocation.DistSquared(GravityBikeSpline::GetGravityBike().ActorLocation) > Math::Square(GravityBikeSpline::CarEnemy::Turret::MaxTargetDistance))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TurretComp.bIsFiring = true;
		TurretComp.LastFireTime = Time::GameTimeSeconds - TurretComp.FireInterval;
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
		TryFire();
	}

	bool IsPlayerTooSlow() const
	{
		if(TurretComp.bFireIfPlayerTooSlow)
		{
			auto GravityBike = GravityBikeSpline::GetGravityBike();
			if(GravityBike == nullptr)
				return false;

			if(!GravityBike.BlockEnemySlowRifleFire.IsEmpty())
				return false;
			
			if(GravityBike.GetSpeedAlpha(GravityBike.GetForwardSpeed()) < GravityBikeSpline::CarEnemy::Turret::FireIfUnderSpeedAlpha)
				return true;
		}

		return false;
	}

	void TryFire()
	{
		while(TurretComp.TimeSinceLastFire() > TurretComp.FireInterval)
		{
			if(TurretComp.IsMagazineEmpty())
				break;

			const FVector Start = TurretComp.GetCurrentMuzzleLocation();

			FPlane TargetPlane = FPlane(TurretComp.GetTargetLocation(), GravityBikeSpline::GetGravityBike().GetSplineUp());

			FVector End = TargetPlane.RayPlaneIntersection(Start, TurretComp.GetCurrentMuzzle().ForwardVector);

			FVector Recoil = TurretComp.GetRecoilOffset();

			if(IsPlayerTooSlow())
				Recoil *= GravityBikeSpline::CarEnemy::Turret::IfUnderSpeedRecoilMultiplier;

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
			float DealtDamage = TurretComp.PlayerDamage;
			if(IsPlayerTooSlow())
				DealtDamage *= GravityBikeSpline::CarEnemy::Turret::IfUnderSpeedDamageMultiplier;

			GravityBikeSpline::TryDamagePlayerHitResult(HitResult, DealtDamage);
		}

		TurretComp.ConsumeBullet();

		FGravityBikeSplineCarEnemyTurretFireEventData FireEventData;
		FireEventData.MuzzleComp = TurretComp.GetCurrentMuzzle();
		FireEventData.StartLocation = Start;
		FireEventData.StartRotation = FireEventData.MuzzleComp.WorldRotation;
		FireEventData.EndLocation = HitResult.IsValidBlockingHit() ? HitResult.ImpactPoint : HitResult.TraceEnd;
		UGravityBikeSplineCarEnemyTurretEventHandler::Trigger_OnFire(CarEnemy, FireEventData);

		if(HitResult.IsValidBlockingHit())
		{
			FGravityBikeSplineCarEnemyTurretHitEventData HitEventData;
			HitEventData.MuzzleComp = TurretComp.GetCurrentMuzzle();
			HitEventData.StartLocation = Start;
			HitEventData.StartRotation = HitEventData.MuzzleComp.WorldRotation;
			HitEventData.HitResult = HitResult;
			UGravityBikeSplineCarEnemyTurretEventHandler::Trigger_OnHit(CarEnemy, HitEventData);
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
				float RecoilAlpha = GravityBikeSplineCarEnemyTurretMuzzleRecoilCurve.GetFloatValue(TimeSinceFire / MuzzleComp.RecoilDuration);
				check(RecoilAlpha == Math::Saturate(RecoilAlpha));
				MuzzleComp.SetRelativeLocation(MuzzleComp.InitialRelativeLocation + FVector(MuzzleComp.RecoilDelta * RecoilAlpha, 0, 0));
			}
		}
	}
};