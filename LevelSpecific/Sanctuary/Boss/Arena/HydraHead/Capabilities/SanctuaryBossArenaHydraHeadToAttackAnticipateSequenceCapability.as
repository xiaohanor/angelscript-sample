class USanctuaryBossArenaHydraHeadToAttackAnticipateSequenceCapability : UHazeCapability
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

		if (HydraHead.TargetPlayer == nullptr)
			return false;
		float DistanceToPlayer = (HydraHead.TargetPlayer.ActorLocation - HydraHead.HeadPivot.WorldLocation).Size();
		if (DistanceToPlayer > HydraHead.Settings.AnticipateSequenceTriggerDistanceToPlayer)
			return false;

		// if (HydraHead.HeadID == ESanctuaryBossArenaHydraHead::Center)
		// {
		// 	if (PlayerIsSoonInSequence(Game::Mio))
		// 		return true;
		// 	if (PlayerIsSoonInSequence(Game::Zoe))
		// 		return true;
		// }
		if (PlayerIsSoonInSequence(HydraHead.TargetPlayer))
			return true;
		return false;
	}

	bool PlayerIsSoonInSequence(AHazePlayerCharacter Player) const
	{
		if (Player == nullptr)
			return false;
		auto TargetAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		if (TargetAviationComp == nullptr)
			return false;
		if (TargetAviationComp.AviationState == EAviationState::ToAttack)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (HydraHead.HeadID == ESanctuaryBossArenaHydraHead::Center)
		// {
		// 	if (PlayerIsSoonInSequence(Game::Mio))
		// 		return false;
		// 	if (PlayerIsSoonInSequence(Game::Zoe))
		// 		return false;
		// }
		if (PlayerIsSoonInSequence(HydraHead.TargetPlayer))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HydraHead.LocalHeadState.bToAttackSequenceAnticipation = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.LocalHeadState.bToAttackSequenceAnticipation = false;
	}
};