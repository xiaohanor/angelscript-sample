class USkylineBallBossAttackLaserCapability : USkylineBallBossChildCapability
{
	float LaserDuration = 20.0;

	USkylineBallBossAttackLaserCapability(float Duration)
	{
		LaserDuration = Duration;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("Duration", LaserDuration);
	}
#endif

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return ActiveDuration > LaserDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LaserDuration = BallBoss.BigLaserActor.LaserSpeedTimeLike.Duration;
		BallBoss.BigLaserActor.ActivateLaser();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.BigLaserActor.DeactivateLaser();
		if (!BallBoss.MioIsOnBall())
		{
			if (BallBoss.GetPhase() == ESkylineBallBossPhase::Top)
				BallBoss.ChangePhase(ESkylineBallBossPhase::TopGrappleFailed1);
			else if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOff2)
				BallBoss.ChangePhase(ESkylineBallBossPhase::TopGrappleFailed2);
		}
	}
}