struct FSanctuaryBossArenaHydraRainDanceActionData
{
}

class USanctuaryBossArenaHydraActionRainDanceCapability : UHazeCapability
{
	FSanctuaryBossArenaHydraRainDanceActionData Params;
	default CapabilityTags.Add(ArenaHydraTags::ArenaHydra);
	default CapabilityTags.Add(ArenaHydraTags::Action);
	ASanctuaryBossArenaHydra Hydra;
	USanctuaryBossArenaHydraActionsComponent BossComp;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossArenaHydra>(Owner);
		BossComp = USanctuaryBossArenaHydraActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossArenaHydraRainDanceActionData& ActivationParams) const
	{
		if (BossComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryBossArenaHydraRainDanceActionData ActivationParams)
	{
		Params = ActivationParams;
		if (BossComp.bDebugPrintActions)
			Print("Arena Hydra Boss Action - Rain Anticipate");
		for (auto Head : Hydra.HydraHeads)
			Head.RainAttack();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.ActionQueue.Finish(this);
	}
}
