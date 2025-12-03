struct FSkylineBallBossSmallBossLaserData
{
	bool bCanLaser = false;
}

class USkylineBallBossSmallBossLaserCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;
	default CapabilityTags.Add(SkylineBallBossTags::SmallBoss);
	ASkylineBallBossSmallBoss SmallBoss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossSmallBossLaserData& Params) const
	{
		if (!SmallBoss.bDoLaser)
			return false;
		Params.bCanLaser = CanLaser();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossSmallBossLaserData Params)
	{
		SmallBoss.bDoLaser = false;
		if (Params.bCanLaser)
		{
			SmallBoss.bLaserActive = true;
			SmallBoss.RollSpeedTimeLike.Reverse();
			Timer::SetTimer(SmallBoss, n"DelayedLaserActivation", 1.5);
		}
	}

	bool CanLaser() const
	{
		if (!SmallBoss.bActive)
			return false;

		if (SmallBoss.JumpTimeLike.IsPlaying())
			return false;

		if (SmallBoss.bWeak)
			return false;

		return true;
	}
};