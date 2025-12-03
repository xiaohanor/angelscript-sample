struct FSanctuaryBossArenaHydraWaveActionData
{
}

class USanctuaryBossArenaHydraActionWaveCapability : UHazeCapability
{
	FSanctuaryBossArenaHydraWaveActionData Params;
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
	bool ShouldActivate(FSanctuaryBossArenaHydraWaveActionData& ActivationParams) const
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
	void OnActivated(FSanctuaryBossArenaHydraWaveActionData ActivationParams)
	{
		Params = ActivationParams;
		if (BossComp.bDebugPrintActions)
			Print("Arena Hydra Boss Action - Wave");
		TListedActors<ASanctuaryBossArenaWave> Waves;
		for (auto Wave : Waves)
			Wave.StartWave();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.ActionQueue.Finish(this);
	}
}
