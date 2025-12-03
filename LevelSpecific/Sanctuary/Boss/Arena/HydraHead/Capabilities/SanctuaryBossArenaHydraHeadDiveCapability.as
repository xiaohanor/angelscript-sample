class USanctuaryBossArenaHydraHeadDiveCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossArenaHydraHead HydraHead;

	FHazeAcceleratedFloat AcceleratedFloat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HydraHead.GetReadableState().bShouldDive)
			return false;

		// make sure local is set to synced state, so we don't activate twice :)
		if (DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HydraHead.GetReadableState().bShouldDive)
			return false;

		if (HydraHead.GetReadableState().bShouldSurface)
			return true;

		if (ActiveDuration > 10.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedFloat.SnapTo(0.0);
		HydraHead.BlockCapabilities(ArenaHydraTags::HydraProjectile, this);
		HydraHead.BlockCapabilities(ArenaHydraTags::HydraRain, this);
		HydraHead.BlockCapabilities(ArenaHydraTags::HydraWave, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.UnblockCapabilities(ArenaHydraTags::HydraProjectile, this);
		HydraHead.UnblockCapabilities(ArenaHydraTags::HydraRain, this);
		HydraHead.UnblockCapabilities(ArenaHydraTags::HydraWave, this);
		HydraHead.LocalHeadState.bShouldDive = false;
		if (HydraHead.GetReadableState().bDisableAfterDive)
		{
			if (HydraHead.Settings.DeathType == EArenaHydraDeadType::Decapitated)
				HydraHead.SwitchToDecapNeck();
			else if (HydraHead.Settings.DeathType == EArenaHydraDeadType::Disabled)
				HydraHead.AddActorDisable(HydraHead);
		}
		else
			HydraHead.LocalHeadState.bShouldSurface = true;
	}
};