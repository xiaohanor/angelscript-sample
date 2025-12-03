class USummitStoneBallExplodeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitStoneBall Ball;
	
	float ExplodeTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitStoneBall>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Ball.CurrentFuseHealth <= 0)
			return true;

		if(Ball.TimeToExplodeFromAdjacentExplosion.IsSet())
			return true;

		if(Ball.bHasHitDespawnVolume)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ExplodeTimer >= Ball.FuseDuration)
			return true;

		if(Ball.TimeToExplodeFromAdjacentExplosion.IsSet()
			&& Time::GameTimeSeconds >= Ball.TimeToExplodeFromAdjacentExplosion.Value)
			return true;

		if(Ball.bHasHitDespawnVolume)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Ball.MeshComp.SetMaterial(0, Ball.FuseMaterial);
		Ball.bIsExploding = true;

		ExplodeTimer = 0.0;
		USummitStoneBallEffectHandler::Trigger_OnBallFuseLit(Ball);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Ball.Explode();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ExplosionAlpha = ExplodeTimer / Ball.FuseDuration;
		float ExplosionScaleUpFrequency = Math::Lerp(Ball.ExplosionScaleUpPulseFrequencyStart, Ball.ExplosionScaleUpPulseFrequencyEnd, ExplosionAlpha);

		float ScaleMagnitude = 1 - (Math::Sin(ActiveDuration * ExplosionScaleUpFrequency) * Ball.LitScaleUpMagnitude);

		Ball.MeshOffsetComp.SetRelativeScale3D(FVector::OneVector * ScaleMagnitude);

		float TimerMultiplier = 1.0;
		TListedActors<ASummitExplodyFruitWallCrack> CracksInLevel;
		for(auto Crack : CracksInLevel.Array)
		{
			if(Crack.ActorLocation.DistSquared(Ball.ActorLocation) < Math::Square(Crack.BallFuseMultiplierDistance))
			{
				TimerMultiplier = Crack.BallFuseMultiplier;
				break;
			}
		}

		ExplodeTimer += (DeltaTime * TimerMultiplier);	
		TEMPORAL_LOG(Ball)
			.Value("Explode Timer", ExplodeTimer)
			.Value("Timer Multiplier", TimerMultiplier)
		;
	}
};