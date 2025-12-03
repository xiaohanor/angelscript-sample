class USkylineBallBossAttackIdleCapability : USkylineBallBossChildCapability
{
	// Can be used either locally or networked
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	float Cooldown = 0.1;
	float Duration = -1.0;

	USkylineBallBossAttackIdleCapability(float IdleDuration)
	{
		Duration = IdleDuration;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("Duration", Duration);
	}
#endif

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration <= Cooldown)
			return false;
		if (BallBoss.ChangedPhaseDramaticPauseTimestamp > KINDA_SMALL_NUMBER)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Duration <= ActiveDuration)
			return true;
		if (BallBoss.ChangedPhaseDramaticPauseTimestamp > KINDA_SMALL_NUMBER)
			return true;
		return false;
	}
}