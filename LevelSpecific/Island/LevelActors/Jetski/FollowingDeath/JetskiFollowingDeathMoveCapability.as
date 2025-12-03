class UJetskiFollowingDeathMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AJetskiFollowingDeath FollowingDeath;
	TPerPlayer<AJetski> Jetskis;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FollowingDeath = Cast<AJetskiFollowingDeath>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!FollowingDeath.IsActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FollowingDeath.IsActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Jetskis = Jetski::GetJetskis();
		InitDistanceAlongSpline();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Plane("Location", FollowingDeath.ActorLocation, FollowingDeath.ActorRotation.ForwardVector, 5000, Color = FLinearColor::Red);
		TemporalLog.Value("Distance Along Spline", FollowingDeath.GetDistanceAlongSpline());
	}
#endif

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float RubberBandFactor = GetRubberBandFactor();
		const float MoveSpeed = Math::Lerp(FollowingDeath.MaxMoveSpeed, FollowingDeath.MinMoveSpeed, RubberBandFactor);

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("RubberBandFactor", RubberBandFactor);
		TemporalLog.Value("MoveSpeed", MoveSpeed);
#endif

		FollowingDeath.DistanceAlongSpline += MoveSpeed * DeltaTime;
		FTransform SplineTransform = Jetski::GetJetskiSpline().Spline.GetWorldTransformAtSplineDistance(FollowingDeath.GetDistanceAlongSpline());
		FollowingDeath.SetActorLocationAndRotation(SplineTransform.Location, SplineTransform.Rotator());

#if EDITOR
		if(FollowingDeath.bDebugDraw)
		{
			Debug::DrawDebugSolidBox(SplineTransform.Location, FVector(0, 5000, 5000), SplineTransform.Rotator(), FLinearColor::Red);
		}
#endif

		for(auto Jetski : Jetskis)
		{
			if(Jetski.Driver.IsPlayerDead() || Jetski.Driver.IsPlayerRespawning())
				continue;

			const float DistanceAlongSpline = Jetski.GetDistanceAlongSpline();

			if(DistanceAlongSpline < FollowingDeath.GetDistanceAlongSpline())
			{
				Jetski.Driver.KillPlayer();
				FollowingDeath.LastPlayerKillTime = Time::GameTimeSeconds;
				//PrintToScreen(f"Kill {Jetski.Driver}!");
			}
		}
	}

	void InitDistanceAlongSpline()
	{
		float FurthestAhead = -BIG_NUMBER;
		for(auto Jetski : Jetskis)
		{
			const float DistanceAlongSpline = Jetski.GetDistanceAlongSpline();

			if(DistanceAlongSpline > FurthestAhead)
				FurthestAhead = DistanceAlongSpline;
		}

		FollowingDeath.DistanceAlongSpline = FurthestAhead - FollowingDeath.MaxSpeedMargin;
	}

	float GetRubberBandFactor() const
	{
		bool bFoundJetski = false;
		float FurthestAhead = -BIG_NUMBER;
		for(auto Jetski : Jetskis)
		{
			if(Jetski.Driver.IsPlayerDead() || Jetski.Driver.IsPlayerRespawning())
				continue;

			bFoundJetski = true;

			const float JetskiDistanceAlongSpline = Jetski.GetDistanceAlongSpline();

			if(JetskiDistanceAlongSpline > FurthestAhead)
				FurthestAhead = JetskiDistanceAlongSpline;
		}

		if(!bFoundJetski)
			return 1.0;

		float Alpha = Math::NormalizeToRange(FollowingDeath.DistanceAlongSpline, FurthestAhead - FollowingDeath.MaxSpeedMargin, FurthestAhead - FollowingDeath.MinSpeedMargin);
		Alpha = Math::Saturate(Alpha);

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("FurthestAhead", FurthestAhead);
		TemporalLog.Value("Alpha", Alpha);
#endif

		return Alpha;
	}
};