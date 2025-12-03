struct FSkylineBallBossSmallBossActionNodeJumpDelayCapabilityData
{
	float Duration;
}

class USkylineBallBossSmallBossActionNodeJumpDelayCapability : UHazeCapability
{
	FSkylineBallBossSmallBossActionNodeJumpDelayCapabilityData Params;
	default CapabilityTags.Add(SkylineBallBossTags::SmallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	USkylineBallBossSmallBossJumpActionComponent BossComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = USkylineBallBossSmallBossJumpActionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossSmallBossActionNodeJumpDelayCapabilityData& ActivationParams) const
	{
		if (BossComp.Queue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossComp.Queue.IsActive(this))
			return true;
		if (ActiveDuration > Params.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossSmallBossActionNodeJumpDelayCapabilityData ActivationParams)
	{
		Params = ActivationParams;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.Queue.Finish(this);
	}
}
