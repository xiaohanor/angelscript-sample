/**
 * This is a giant hack to shuttle input over to the other side in PIE network for easier testing!
 */
class UTestPinballFlipRightCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Pinball::UseTestInputShortcuts())
			return false;
		if (!Player.HasControl())
			return false;
		if(!IsActioning(GetRightAction()))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if(!IsActioning(GetRightAction()))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GetUsedCapability().NetActivation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GetUsedCapability().NetDeactivation();
	}

	FName GetRightAction() const
	{
		if(Player.IsUsingGamepad())
			return ActionNames::Grapple;
		else
			return ActionNames::UI_Right;
	}

	const UTestPinballFlipRightCapability GetUsedCapability() const
	{
#if EDITOR
		if (Network::IsGameNetworked())
			return Cast<UTestPinballFlipRightCapability>(Debug::GetPIENetworkOtherSideForDebugging(this));
#endif

		return this;
	}

	UFUNCTION(NetFunction)
	void NetActivation() const
	{
		Pinball::GetManager().StartHolding(false, 1);
	}

	UFUNCTION(NetFunction)
	void NetDeactivation() const
	{
		Pinball::GetManager().StopHolding(false);
	}
}