class UMagnetDroneNoMagneticSurfaceFoundCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneNoMagneticSurfaceFound);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileChainJumping);

	default TickGroup = MagnetDrone::StartAttractTickGroup;
	default TickGroupOrder = MagnetDrone::StartAttractTickGroupOrder;
	default TickGroupSubPlacement = 200;

	UMagnetDroneAttractionComponent AttractionComp;
	UMagnetDroneAttachedComponent AttachedComp;

    const float DELAY = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttractionComp.IsInputtingAttract())
			return false;

		if(AttractionComp.HasSetStartAttractTargetThisFrame())
			return false;

		if(AttachedComp.WasRecentlyMagneticallyAttached())
			return false;

        if(DeactiveDuration < DELAY)
            return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttractionComp.IsInputtingAttract())
			return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMagnetDroneEventHandler::Trigger_NoMagneticSurfaceFound(Player);
	}
}