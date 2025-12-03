struct FSkylineBallBossSmallBossActionNodeLaserCapabilityData
{
}

class USkylineBallBossSmallBossActionNodeLaserCapability : UHazeCapability
{
	FSkylineBallBossSmallBossActionNodeLaserCapabilityData Params;
	default CapabilityTags.Add(SkylineBallBossTags::SmallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	USkylineBallBossSmallBossJumpActionComponent BossComp;
	ASkylineBallBossSmallBoss SmallBoss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(Owner);
		BossComp = USkylineBallBossSmallBossJumpActionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossSmallBossActionNodeLaserCapabilityData& ActivationParams) const
	{
		if (BossComp.Queue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SmallBoss.bDoLaser)
			return false;
		if (SmallBoss.bLaserActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossSmallBossActionNodeLaserCapabilityData ActivationParams)
	{
		SmallBoss.bDoLaser = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.Queue.Finish(this);
	}
}
