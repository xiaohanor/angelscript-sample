

struct FSanctuaryCompanionAviationPhase1DisableDeathActivationParams
{
}
class USanctuaryCompanionAviationPhase1DisableDeathCapability : UHazePlayerCapability
{
	FSanctuaryCompanionAviationPhase1DisableDeathActivationParams ActivationParams;
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryCompanionAviationPlayerComponent AviationComp;
	USanctuaryCompanionAviationDestinationComponent DestinationComp;
	ASanctuaryBossArenaHydra ArenaHydra;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		DestinationComp = USanctuaryCompanionAviationDestinationComponent::GetOrCreate(Player);
		TListedActors<ASanctuaryBossArenaHydra> Hydras;
		ArenaHydra = Hydras.Single;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryCompanionAviationPhase1DisableDeathActivationParams& Params) const
	{
		if (!HasControl())
			return false;
		TListedActors<ASanctuaryBossArenaHydra> Hydras;
		if (Hydras.Num() == 0)
			return false;
		if (!Hydras.Single.IsDefeated())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryCompanionAviationPhase1DisableDeathActivationParams Params)
	{
		ActivationParams = Params;
		Player.BlockCapabilities(n"Death", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"Death", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Hydra specialcase - Disabled Death for " + Player.GetName());
	}
};

