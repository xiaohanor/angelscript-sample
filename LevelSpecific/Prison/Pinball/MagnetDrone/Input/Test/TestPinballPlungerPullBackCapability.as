class UTestPinballPlungerPullBackCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(Pinball::Tags::Pinball);
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Pinball::UseTestInputShortcuts())
			return false;

		if (!Player.HasControl())
			return false;

		if(Player.IsUsingGamepad())
		{
			if(GetAttributeFloat(AttributeNames::CameraPitch) > -0.5)
				return false;
		}
		else
		{
			if(!IsActioning(ActionNames::UI_Down))
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if(Player.IsUsingGamepad())
		{
			if(GetAttributeFloat(AttributeNames::CameraPitch) > -0.5)
				return true;
		}
		else
		{
			if(!IsActioning(ActionNames::UI_Down))
				return true;
		}

		return false;
	}

	const UTestPinballPlungerPullBackCapability GetUsedCapability() const
	{
#if EDITOR
		if (Network::IsGameNetworked())
			return Cast<UTestPinballPlungerPullBackCapability>(Debug::GetPIENetworkOtherSideForDebugging(this));
#endif

		return this;
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

	UFUNCTION(NetFunction)
	void NetActivation() const
	{
		Pinball::GetManager().StartPlungerPullBack();
	}

	UFUNCTION(NetFunction)
	void NetDeactivation() const
	{
		Pinball::GetManager().StopPlungerPullBack();
	}
}