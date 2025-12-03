struct FMagnetDroneAttractionLaunchActivatedParams
{
	FMagnetDroneTargetData AimData;
}

class UMagnetDroneStartAttractAimCapability : UHazePlayerCapability
{
	// We just sync with a CrumbFunction instead to save a crumb when deactivating
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileChainJumping);

	default TickGroup = MagnetDrone::StartAttractTickGroup;
	default TickGroupOrder = MagnetDrone::StartAttractTickGroupOrder;
	default TickGroupSubPlacement = 100;

	UMagnetDroneAttractAimComponent AttractAimComp;
	UMagnetDroneAttractionComponent AttractionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttractAimComp = UMagnetDroneAttractAimComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetDroneAttractionLaunchActivatedParams& Params) const
	{
		if(!HasControl())
			return false;

		if(!AttractionComp.IsInputtingAttract())
			return false;

		if(AttractionComp.HasSetStartAttractTargetThisFrame())
			return false;

		if(!AttractAimComp.HasValidAimTarget())
			return false;

		Params.AimData = AttractAimComp.AimData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetDroneAttractionLaunchActivatedParams Params)
	{
		CrumbStartAttractTarget(Params);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttractTarget(FMagnetDroneAttractionLaunchActivatedParams Params)
	{
		AttractionComp.SetStartAttractTarget(Params.AimData, EMagnetDroneStartAttractionInstigator::Aim);
	}
}