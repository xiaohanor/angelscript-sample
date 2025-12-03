class UPinballMagnetAttractionInputCapability : UHazePlayerCapability
{
	// Input is always local
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileChainJumping);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UMagnetDroneAttractionComponent AttractionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!AttractionComp.IsAttractionInputAllowed())
			return false;

		if(!WasActionStartedDuringTime(MagnetDrone::MagnetInput, AttractionComp.Settings.InputBuffer))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsActioning(MagnetDrone::MagnetInput))
			return true;

		if(AttractionComp.IsAttracting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttractionComp.bAttractionInput = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AttractionComp.bAttractionInput = false;
	}
};