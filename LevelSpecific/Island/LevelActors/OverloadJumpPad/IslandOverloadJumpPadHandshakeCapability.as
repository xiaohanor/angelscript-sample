struct FIslandOverloadJumpPadHandshakeActivatedParams
{
	AHazePlayerCharacter Player;
}

class UIslandOverloadJumpPadHandshakeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	AIslandOverloadJumpPad JumpPad;
	AHazePlayerCharacter Player;
	bool bReceivedResponse = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpPad = Cast<AIslandOverloadJumpPad>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandOverloadJumpPadHandshakeActivatedParams& Params) const
	{
		if(!Network::IsGameNetworked())
			return false;

		// This should only run on the host side, so that we don't have both launchpads trying to control each other.
		if(!World.HasControl())
			return false;

		if(!JumpPad.bRequireSecondPanel)
			return false;

		if(!JumpPad.bFirstPanelIsOvercharged)
			return false;
		
		if(!JumpPad.bSecondPanelIsOverCharged)
			return false;

		if(JumpPad.PlayersInsideBox.Num() == 0)
			return false;

		Params.Player = JumpPad.PlayersInsideBox[0];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bReceivedResponse)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandOverloadJumpPadHandshakeActivatedParams Params)
	{
		bReceivedResponse = false;
		if(!HasControl())
			NetSetShouldLaunch(JumpPad.OtherJumpPad.PlayersInsideBox.Num() > 0);

		Player = Params.Player;
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::ContextualMovement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::ContextualMovement, this);
	}

	UFUNCTION(NetFunction)
	private void NetSetShouldLaunch(bool bShouldLaunch)
	{
		bReceivedResponse = true;
		if(bShouldLaunch)
		{
			JumpPad.bHandshakeSuccessful = true;
			JumpPad.OtherJumpPad.bHandshakeSuccessful = true;
		}
	}
}