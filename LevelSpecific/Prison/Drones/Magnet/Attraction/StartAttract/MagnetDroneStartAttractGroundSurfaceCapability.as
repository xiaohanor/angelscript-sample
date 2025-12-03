struct FMagnetDroneAttractToGroundSurfaceActivateParams
{
	FMagnetDroneTargetData TargetData;
}

class UMagnetDroneStartAttractGroundSurfaceCapability : UHazePlayerCapability
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
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileChainJumping);

	default TickGroup = MagnetDrone::StartAttractTickGroup;
	default TickGroupOrder = MagnetDrone::StartAttractTickGroupOrder;
	default TickGroupSubPlacement = 110;

	UMagnetDroneAttractAimComponent AttractAimComp;
	UMagnetDroneAttractionComponent AttractionComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttractAimComp = UMagnetDroneAttractAimComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetDroneAttractToGroundSurfaceActivateParams& Params) const
	{
		if(!HasControl())
			return false;

		if(!AttractionComp.Settings.bAttachToGroundIfNoTargetFound)
			return false;

		if(!AttractionComp.IsInputtingAttract())
			return false;

		if(AttractionComp.IsAttracting())
			return false;

		if(AttachedComp.WasRecentlyMagneticallyAttached())
			return false;

		if(AttractionComp.HasSetStartAttractTargetThisFrame())
			return false;

		FMovementHitResult AnyValidContact;
		if(!MoveComp.GetAnyValidContact(AnyValidContact))
			return false;

		FHitResult Impact = AnyValidContact.ConvertToHitResult();

		if(!MagnetDrone::IsHitMagnetic(Impact, true))
			return false;

		auto GroundComp = Cast<UPrimitiveComponent>(Impact.Component);

		if(GroundComp == nullptr)
			return false;

		FHitResult Hit;
		Hit.bBlockingHit = true;
		Hit.Actor = GroundComp.Owner;
		Hit.Component = GroundComp;
		Hit.ImpactPoint = Impact.ImpactPoint;
		Hit.ImpactNormal = Impact.ImpactNormal;

		const auto TargetData = FMagnetDroneTargetData::MakeFromHit(
			Hit,
			false,
			true
		);

		if(!TargetData.IsValidTarget())
			return false;

		if(TargetData.HasAutoAimTarget())
		{
			const float DistanceToZone = TargetData.GetAutoAimComp().DistanceFromPoint(Hit.ImpactPoint);
			if(DistanceToZone > MagnetDrone::Radius)
				return false;
		}

		Params.TargetData = TargetData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetDroneAttractToGroundSurfaceActivateParams Params)
	{
		CrumbStartAttractTarget(Params);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttractTarget(FMagnetDroneAttractToGroundSurfaceActivateParams Params)
	{
		AttractionComp.SetStartAttractTarget(Params.TargetData, EMagnetDroneStartAttractionInstigator::GroundSurface);
	}
}