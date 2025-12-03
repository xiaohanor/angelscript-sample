class USkylineBallBossAttackSwingLaserCapability : USkylineBallBossChildCapability
{
	int TotalSwings = 0;

	USkylineBallBossAttackSwingLaserCapability(int Swings)
	{
		TotalSwings = Swings;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("Duration", TotalSwings);
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
		return !BallBoss.bSwingLaser;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BallBoss.NumLaserSwings = TotalSwings;
		BallBoss.bSwingLaser = true;
	}
}