class USanctuaryBossArenaHydraHeadShouldDiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
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
		// make sure local is set to synced state, so we don't activate twice :)
		if (DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		if (HydraHead.HeadID == ESanctuaryBossArenaHydraHead::Center)
			return false;
		if (PlayerIsInExit(HydraHead.TargetPlayer))
			return true;
		return false;
	}

	bool PlayerIsInExit(AHazePlayerCharacter Player) const
	{
		if (Player == nullptr)
			return false;
		auto TargetAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		if (TargetAviationComp == nullptr)
			return false;
		if (TargetAviationComp.AviationState == EAviationState::TryExitAttack)
			return true;
		if (TargetAviationComp.AviationState == EAviationState::Exit)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (HydraHead.HeadID == ESanctuaryBossArenaHydraHead::Center)
		// {
		// 	if (PlayerIsInExit(Game::Mio))
		// 		return false;
		// 	if (PlayerIsInExit(Game::Zoe))
		// 		return false;
		// }

		if (PlayerIsInExit(HydraHead.TargetPlayer))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HydraHead.LocalHeadState.bShouldDive = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};