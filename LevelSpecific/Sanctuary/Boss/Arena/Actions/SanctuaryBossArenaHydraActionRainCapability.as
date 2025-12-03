struct FSanctuaryBossArenaHydraRainActionData
{
}

class USanctuaryBossArenaHydraActionRainCapability : UHazeCapability
{
	FSanctuaryBossArenaHydraRainActionData Params;
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
	bool ShouldActivate(FSanctuaryBossArenaHydraRainActionData& ActivationParams) const
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
	void OnActivated(FSanctuaryBossArenaHydraRainActionData ActivationParams)
	{
		Params = ActivationParams;
		Print("Arena Hydra Boss Action - Ghost Rain");
		TListedActors<ASanctuaryBossArenaGhostRainManager> RainManagers;
		for (auto RainyDay : RainManagers)
			RainyDay.StartGhostRain();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.ActionQueue.Finish(this);
	}
}
