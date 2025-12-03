struct FSkylineBallBossSmallBossActionNodeProjectileDelayCapabilityData
{
	float Duration;
}

class USkylineBallBossSmallBossActionNodeProjectileDelayCapability : UHazeCapability
{
	FSkylineBallBossSmallBossActionNodeProjectileDelayCapabilityData Params;
	default CapabilityTags.Add(SkylineBallBossTags::SmallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	USkylineBallBossSmallBossProjectileActionComponent BossComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = USkylineBallBossSmallBossProjectileActionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossSmallBossActionNodeProjectileDelayCapabilityData& ActivationParams) const
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
	void OnActivated(FSkylineBallBossSmallBossActionNodeProjectileDelayCapabilityData ActivationParams)
	{
		Params = ActivationParams;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.Queue.Finish(this);
	}
}
