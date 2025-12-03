struct FSummitSeeSawSwingStatuePlayerDisableRespawnActivationParams
{
	ASummitSeeSawSwingStatue Statue;
}

class USummitSeeSawSwingStatuePlayerDisableRespawnCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	USummitSeeSawSwingStatuePlayerComponent StatueComp;
	UPlayerMovementComponent MoveComp;
	UPlayerMovementComponent OtherMoveComp;

	ASummitSeeSawSwingStatue CurrentStatue;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StatueComp = USummitSeeSawSwingStatuePlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		OtherMoveComp = UPlayerMovementComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitSeeSawSwingStatuePlayerDisableRespawnActivationParams& Params) const
	{
		if(StatueComp.PreviousStatue == nullptr)
			return false;
		
		if(StatueComp.PreviousStatue.bHasReEnabledRespawnAfterSwingsDeactivating)
			return false;

		auto Statue = StatueComp.PreviousStatue;
		if(!Statue.bBlockRespawnAfterDisableSwing)
			return false;

		if(MoveComp.IsOnWalkableGround()
		|| OtherMoveComp.IsOnWalkableGround())
			return false;

		if(Game::Mio.IsPlayerDead()
		&& Game::Zoe.IsPlayerDead())
			return false;

		if(Statue.bSwingsDeactivated)
		{
			Params.Statue = Statue;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CurrentStatue.bBlockRespawnAfterDisableSwing)
			return true;

		if(CurrentStatue.bRespawnPointActivated)
			return true;

		if(MoveComp.IsOnWalkableGround()
		|| OtherMoveComp.IsOnWalkableGround())
			return true;

		if(Game::Mio.IsPlayerDead()
		&& Game::Zoe.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitSeeSawSwingStatuePlayerDisableRespawnActivationParams Params)
	{
		CurrentStatue = Params.Statue;
		Player.BlockCapabilities(CapabilityTags::Respawn, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Respawn, this);
		CurrentStatue.bHasReEnabledRespawnAfterSwingsDeactivating = true; 
	}
};