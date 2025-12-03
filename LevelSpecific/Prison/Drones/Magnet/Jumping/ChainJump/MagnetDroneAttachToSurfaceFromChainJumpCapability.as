struct FMagnetDroneAttachToSurfaceFromChainActivateParams
{
	FMagnetDroneTargetData TargetData;
}

class UMagnetDroneAttachToSurfaceFromChainJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAttachToSurface);

	default TickGroup = MagnetDrone::AttachToTickGroup;
	default TickGroupOrder = MagnetDrone::AttachToTickGroupOrder;
	default TickGroupSubPlacement = 90;

	UMagnetDroneChainJumpComponent ChainJumpComp;
	UMagnetDroneAttractionComponent AttractionComp;
	UMagnetDroneAttachedComponent AttachedComp;

	UHazeMovementComponent MoveComp;
    USweepingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ChainJumpComp = UMagnetDroneChainJumpComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);

        MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetDroneAttachToSurfaceFromChainActivateParams& Params) const
	{
		if(!ChainJumpComp.WasChainJumpingThisFrame())
			return false;

		if(!MoveComp.HasAnyValidBlockingImpacts())
			return false;

		const FHitResult FirstImpact = MoveComp.AllImpacts[0].ConvertToHitResult();
		if(!FirstImpact.IsValidBlockingHit())
			return false;

		const auto TargetData = FMagnetDroneTargetData::MakeFromHit(FirstImpact, false, true);

		if(!TargetData.IsValidTarget())
			return false;

		if(!TargetData.IsSurface())
			return false;

		Params.TargetData = TargetData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetDroneAttachToSurfaceFromChainActivateParams Params)
	{
		FMagnetDroneTargetData TargetData = Params.TargetData;
		AttachedComp.AttachToSurface(TargetData, FMagnetDroneAttractionStartedParams(), this);
	}
}