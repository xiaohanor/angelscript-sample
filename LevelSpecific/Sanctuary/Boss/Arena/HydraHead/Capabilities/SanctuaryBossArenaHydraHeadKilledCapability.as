class USanctuaryBossArenaHydraHeadKilledCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;
	ASanctuaryBossArenaHydraHead HydraHead;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HydraHead.HeadID != ESanctuaryBossArenaHydraHead::Center)
			return false;
		if (!PlayersAreKillingMe())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HydraHead.LocalHeadState.bShouldSurface)
			return true;
		return false;
	}

	bool PlayersAreKillingMe() const
	{
		USanctuaryCompanionAviationPlayerComponent MioAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Game::Mio);
		USanctuaryCompanionAviationPlayerComponent ZoeAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Game::Zoe);
		if (MioAviationComp == nullptr)
			return false;
		if (ZoeAviationComp == nullptr)
			return false;

		bool bMioSuccess = MioAviationComp.SyncedKillValue.Value <= KINDA_SMALL_NUMBER;
		bool bZoeSuccess = ZoeAviationComp.SyncedKillValue.Value <= KINDA_SMALL_NUMBER;
		if (!CompanionAviation::bCoopKill)
			return bMioSuccess || bZoeSuccess;
		return bMioSuccess && bZoeSuccess;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HydraHead.LocalHeadState.bBleedDying = true;
		TListedActors<ASanctuaryBossArenaHydra> Hydra;
		Hydra.Single.KillHead(HydraHead.HeadID);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.LocalHeadState.bBleedDying = false;
	}
};