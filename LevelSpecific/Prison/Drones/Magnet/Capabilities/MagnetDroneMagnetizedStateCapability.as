class UMagnetDroneMagnetizedStateCapability : UHazePlayerCapability
{
	// Local since both Attraction and Attached states are synced elsewhere
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttractionComponent AttractionComp;
	UMagnetDroneAttachedComponent AttachedComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttractionComp.IsAttracting() && !AttachedComp.IsAttached())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttractionComp.IsAttracting() && !AttachedComp.IsAttached())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DroneComp.bIsMagnetic = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DroneComp.bIsMagnetic = false;
	}
}