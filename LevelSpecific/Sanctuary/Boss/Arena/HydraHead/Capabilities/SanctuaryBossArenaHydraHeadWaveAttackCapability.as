class USanctuaryBossArenaHydraHeadWaveAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ArenaHydraTags::HydraWave);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossArenaHydraHead HydraHead;

	float AttackDuration = 4.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HydraHead.GetReadableState().bWaveAttack)
			return false;
		
		// make sure local is set to synced state, so we don't activate twice :)
		if (Time::GameTimeSeconds > 2.0 && DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > AttackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HydraHead.BlockCapabilities(ArenaHydraTags::HydraProjectile, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.UnblockCapabilities(ArenaHydraTags::HydraProjectile, this);
		HydraHead.LocalHeadState.bWaveAttack = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};