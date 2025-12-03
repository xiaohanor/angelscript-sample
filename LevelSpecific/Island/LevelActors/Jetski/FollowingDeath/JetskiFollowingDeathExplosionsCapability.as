class UJetskiFollowingDeathExplosionsCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AJetskiFollowingDeath FollowingDeath;
	TPerPlayer<AJetski> Jetskis;

	float NextExplosionTime = 0;

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
		NextExplosionTime = 0.0;
		Jetskis = Jetski::GetJetskis();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		switch(FollowingDeath.ExplosionMode)
		{
			case EJetskiFollowingDeathExplosionMode::Always:
			{
				ModeAlways();
				break;
			}

			case EJetskiFollowingDeathExplosionMode::OnlyWhenPlayerClose:
			{
				ModeOnlyWhenPlayerClose();
				break;
			}

			case EJetskiFollowingDeathExplosionMode::OnPlayerKilled:
			{
				ModeOnPlayerKilled();
				break;
			}
		}
	}

	private void ModeAlways()
	{
		// Not enough time has passed
		if(Time::GameTimeSeconds < NextExplosionTime)
			return;

		SpawnExplosion();
	}

	private void ModeOnlyWhenPlayerClose()
	{
		bool bFoundJetski = false;
		float FurthestBack = BIG_NUMBER;
		for(auto Jetski : Jetskis)
		{
			if(Jetski.Driver.IsPlayerDead() || Jetski.Driver.IsPlayerRespawning())
				continue;

			bFoundJetski = true;

			const float JetskiDistanceAlongSpline = Jetski.GetDistanceAlongSpline();

			if(JetskiDistanceAlongSpline < FurthestBack)
				FurthestBack = JetskiDistanceAlongSpline;
		}

		if(!bFoundJetski)
			return;

		// Too far away
		if(FurthestBack - FollowingDeath.GetDistanceAlongSpline() > FollowingDeath.PlayerCloseMargin)
			return;

		if(Time::GameTimeSeconds < NextExplosionTime)
			return;
		
		SpawnExplosion();
	}

	private void ModeOnPlayerKilled()
	{
		// We didn't kill anyone recently
		if(Time::GetGameTimeSince(FollowingDeath.GetLastPlayerKillTime()) > FollowingDeath.OnPlayerKilledExplosionDuration)
			return;

		if(Time::GameTimeSeconds < NextExplosionTime)
			return;

		SpawnExplosion();
	}

	void SpawnExplosion()
	{
		int Index = Math::RandRange(0, FollowingDeath.Explosions.Num() - 1);
		UNiagaraSystem Explosion = FollowingDeath.Explosions[Index];

		const FTransform SplineTransform = Jetski::GetJetskiSpline().Spline.GetWorldTransformAtSplineDistance(FollowingDeath.GetDistanceAlongSpline());

		float SideLocation = Math::RandRange(-SplineTransform.Scale3D.Y, SplineTransform.Scale3D.Y);

		FVector Location = SplineTransform.TransformPositionNoScale(FVector(0, SideLocation, 0));
		Location.Z = Jetski::GetWaveHeightAtLocation(Location, this);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(Explosion, Location);

		float Interval = Math::RandRange(FollowingDeath.ExplosionMinInterval, FollowingDeath.ExplosionMaxInterval);
		Interval /= (SplineTransform.Scale3D.Y / FollowingDeath.ExplosionSplineWidthDivider);
		NextExplosionTime = Time::GameTimeSeconds + Interval;
	}
};