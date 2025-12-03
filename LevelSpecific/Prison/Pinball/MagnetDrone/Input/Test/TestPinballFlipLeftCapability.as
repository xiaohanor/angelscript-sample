/**
 * This is a giant hack to shuttle input over to the other side in PIE network for easier testing!
 */
class UTestPinballFlipLeftCapability : UHazePlayerCapability
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
		if(!IsActioning(GetLeftAction()))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if(!IsActioning(GetLeftAction()))
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

	FName GetLeftAction() const
	{
		if(Player.IsUsingGamepad())
			return ActionNames::DebugCameraDecreaseSpeed;
		else
			return ActionNames::UI_Left;
	}

	const UTestPinballFlipLeftCapability GetUsedCapability() const
	{
#if EDITOR
		if (Network::IsGameNetworked())
			return Cast<UTestPinballFlipLeftCapability>(Debug::GetPIENetworkOtherSideForDebugging(this));
#endif

		return this;
	}

	UFUNCTION(NetFunction)
	void NetActivation() const
	{
		Pinball::GetManager().StartHolding(true, 1);
	}

	UFUNCTION(NetFunction)
	void NetDeactivation() const
	{
		Pinball::GetManager().StopHolding(true);
	}
}