class USanctuaryBossArenaHydraHeadToAttackIncomingStrangleCapability : UHazeCapability
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
		{
			if (PlayerIsInitAttack(Game::Mio))
				return true;
			if (PlayerIsInitAttack(Game::Zoe))
				return true;
		}
		if (PlayerIsInitAttack(HydraHead.TargetPlayer))
			return true;
		return false;
	}

	bool PlayerIsInitAttack(AHazePlayerCharacter Player) const
	{
		if (Player == nullptr)
			return false;
		auto TargetAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		if (TargetAviationComp == nullptr)
			return false;
		if (TargetAviationComp.AviationState == EAviationState::InitAttack)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HydraHead.HeadID == ESanctuaryBossArenaHydraHead::Center)
		{
			if (PlayerIsInitAttack(Game::Mio))
				return false;
			if (PlayerIsInitAttack(Game::Zoe))
				return false;
		}

		if (PlayerIsInitAttack(HydraHead.TargetPlayer))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HydraHead.LocalHeadState.bIncomingStrangle = true;
		// if (HydraHead.HeadID == ESanctuaryBossArenaHydraHead::Center)
		// else
		// 	HydraHead.LocalHeadState.bShouldDive = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// if (HydraHead.HeadID == ESanctuaryBossArenaHydraHead::Center)
		HydraHead.LocalHeadState.bIncomingStrangle = false;
	}
};