struct FSanctuaryBossArenaHydraActionIdleData
{
	float Duration;
}

class USanctuaryBossArenaHydraActionIdleCapability : UHazeCapability
{
	FSanctuaryBossArenaHydraActionIdleData Params;
	default CapabilityTags.Add(ArenaHydraTags::ArenaHydra);
	default CapabilityTags.Add(ArenaHydraTags::Action);
	USanctuaryBossArenaHydraActionsComponent BossComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = USanctuaryBossArenaHydraActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossArenaHydraActionIdleData& ActivationParams) const
	{
		if (BossComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossComp.ActionQueue.IsActive(this))
			return true;
		if (ActiveDuration > Params.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryBossArenaHydraActionIdleData ActivationParams)
	{
		Params = ActivationParams;
		if (BossComp.bDebugPrintActions)
			Print("Arena Hydra boss idle");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.ActionQueue.Finish(this);
	}
}
