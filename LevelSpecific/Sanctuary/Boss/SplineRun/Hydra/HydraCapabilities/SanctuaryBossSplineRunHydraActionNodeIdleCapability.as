struct FSanctuaryBossSplineRunHydraActionNodeIdleData
{
	float Duration;
}

class USanctuaryBossSplineRunHydraActionNodeIdleCapability : UHazeCapability
{
	FSanctuaryBossSplineRunHydraActionNodeIdleData Params;
	default CapabilityTags.Add(ArenaHydraTags::SplineRunHydra);
	default CapabilityTags.Add(ArenaHydraTags::Action);
	USanctuaryBossSplineRunHydraActionComponent BossComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = USanctuaryBossSplineRunHydraActionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossSplineRunHydraActionNodeIdleData& ActivationParams) const
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
	void OnActivated(FSanctuaryBossSplineRunHydraActionNodeIdleData ActivationParams)
	{
		Params = ActivationParams;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.Queue.Finish(this);
	}
}
