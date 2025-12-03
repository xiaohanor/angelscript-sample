struct FGravityBikeSplineEnforcerFireActivateParams
{
	float InitialFireDelay = 0;
};

class UGravityBikeSplineEnforcerFireCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineEnforcer Enforcer;
	float LastFireTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enforcer = Cast<AGravityBikeSplineEnforcer>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeSplineEnforcerFireActivateParams& Params) const
	{
		if(!Enforcer.IsActive())
			return false;

		if(!GravityBikeSpline::GetGravityBike().BlockEnemyRifleFire.IsEmpty())
			return false;

		if(Enforcer.GrabTargetComp.IsGrabbedOrThrown())
			return false;

		Params.InitialFireDelay = Math::RandRange(0, GravityBikeSpline::Enforcer::FireInterval);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Enforcer.IsActive())
			return true;

		if(!GravityBikeSpline::GetGravityBike().BlockEnemyRifleFire.IsEmpty())
			return true;

		if(Enforcer.GrabTargetComp.IsGrabbedOrThrown())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineEnforcerFireActivateParams Params)
	{
		// Stop the enforcers from all firing at the same time
		LastFireTime = Time::GameTimeSeconds - Params.InitialFireDelay;

		Enforcer.bIsShooting = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Enforcer.bIsShooting = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TimeSinceLastFire() > GravityBikeSpline::Enforcer::FireInterval)
		{
			const FVector Start = Enforcer.MeshComp.GetSocketLocation(n"RightAttach");
			FVector TargetLocation = GetTargetLocation();

			FVector Recoil = GetRecoilOffset();

			TargetLocation += Recoil;

			const FVector FireDirection = (TargetLocation - Start).GetSafeNormal();

			Fire(Start, FireDirection);
		}
	}

	void Fire(FVector Start, FVector Direction)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.IgnoreActor(Owner);
		Trace.UseLine();

		FVector End = Start + Direction * GravityBikeSpline::Enforcer::Range;

		FHitResult HitResult = Trace.QueryTraceSingle(Start, End);

		if(HitResult.bBlockingHit)
		{
			float DealtDamage = GravityBikeSpline::Enforcer::PlayerDamage;
			GravityBikeSpline::TryDamagePlayerHitResult(HitResult, DealtDamage);
		}

		LastFireTime = Time::GameTimeSeconds;

		FGravityBikeSplineEnforcerFireEventData EventData;
		EventData.Range = GravityBikeSpline::Enforcer::Range;
		EventData.HitResult = HitResult;
		EventData.StartLocation = Start;
		EventData.StartDirection = Direction;
		UGravityBikeSplineEnforcerEventHandler::Trigger_OnFire(Enforcer, EventData);

		if(HitResult.bBlockingHit)
			UGravityBikeSplineEnforcerEventHandler::Trigger_OnFireTraceImpact(Enforcer, EventData);
	}

	FVector GetRecoilOffset() const
	{
		return Math::GetRandomPointInSphere() * GravityBikeSpline::Enforcer::Recoil;
	}

	float TimeSinceLastFire() const
	{
		return Time::GetGameTimeSince(LastFireTime);
	}

	FVector GetTargetLocation() const
	{
		const FVector ViewLocation = Game::Mio.ViewLocation;

		const AGravityBikeSpline GravityBike = GravityBikeSpline::GetGravityBike();
		if(GravityBike == nullptr)
			return ViewLocation;

		const FVector BikeLocation = GravityBike.ActorCenterLocation;

		const float ViewToBikeAlpha = GetLerpViewToBikeAlpha();

		return Math::Lerp(
			BikeLocation,
			ViewLocation,
			ViewToBikeAlpha
		);
	}

	float GetLerpViewToBikeAlpha() const
	{
		const AGravityBikeSpline GravityBike = GravityBikeSpline::GetGravityBike();
		if(GravityBike == nullptr)
			return 0;

		if(!GravityBike.BlockEnemySlowRifleFire.IsEmpty())
			return 0;
		
		const float SpeedAlpha = GravityBike.GetSpeedAlpha(GravityBike.GetForwardSpeed());
		return Math::GetMappedRangeValueClamped(
			FVector2D(GravityBikeSpline::Enforcer::FireAtBikeSpeedAlpha, 1),
			FVector2D(0, 1),
			SpeedAlpha
		);
	}
};