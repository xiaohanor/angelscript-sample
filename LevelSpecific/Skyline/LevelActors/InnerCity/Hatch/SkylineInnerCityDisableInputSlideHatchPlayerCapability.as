class USkylineInnerCityDisableInputSlideHatchPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent MoveComp;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsAnyCapabilityActive(SkylineInnerPlayerBackwardsSomersaultTags::SkylineInnerPlayerBackwardsSomersault))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.IsOnAnyGround())
			return true;
		if (Player.IsPlayerDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(PlayerSwimmingTags::SwimmingUnderwaterInput, this);
		Player.BlockCapabilities(PlayerSwimmingTags::SwimmingDash, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(PlayerSwimmingTags::SwimmingUnderwaterInput, this);
		Player.UnblockCapabilities(PlayerSwimmingTags::SwimmingDash, this);
	}
};