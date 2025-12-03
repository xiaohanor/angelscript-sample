class USanctuaryBossArenaHydraHeadSurfaceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

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
		if (!HydraHead.GetReadableState().bShouldSurface)
			return false;

		// make sure local is set to synced state, so we don't activate twice :)
		if (DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > HydraHead.Settings.SurfaceDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HydraHead.LocalHeadState.bFriendDeath = false;
		HydraHead.LocalHeadState.bShouldDive = false;
		AcceleratedFloat.SnapTo(0.0);
		HydraHead.ChangedSide();
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
		HydraHead.LocalHeadState.bShouldSurface = false;
	}
};