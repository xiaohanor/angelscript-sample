class USanctuaryBossArenaHydraHeadFriendDeathCapability : UHazeCapability
{
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
		if (!HydraHead.IsInFriendDeath())
			return false;

		// make sure local is set to synced state, so we don't activate twice :)
		if (DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HydraHead.IsInFriendDeath())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HydraHead.LocalHeadState.bFriendDeath = true;
		HydraHead.LocalHeadState.bShouldDive = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HydraHead.GetReadableState().bDisableAfterDive)
		{
			if (HydraHead.Settings.DeathType == EArenaHydraDeadType::Decapitated)
				HydraHead.SwitchToDecapNeck();
			else if (HydraHead.Settings.DeathType == EArenaHydraDeadType::Disabled)
				HydraHead.AddActorDisable(HydraHead);
		}
	}
};