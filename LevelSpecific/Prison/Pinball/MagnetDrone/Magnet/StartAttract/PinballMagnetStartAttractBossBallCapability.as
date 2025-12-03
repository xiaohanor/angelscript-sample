struct FPinballMagnetAttractionBossBallActivatedParams
{
	FMagnetDroneTargetData AimData;
}

class UPinballMagnetStartAttractBossBallCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAttraction);

	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);

	default TickGroup = MagnetDrone::StartAttractTickGroup;
	default TickGroupOrder = MagnetDrone::StartAttractTickGroupOrder;
	default TickGroupSubPlacement = 90;

	UMagnetDroneAttractAimComponent AttractAimComp;
	UMagnetDroneAttractionComponent AttractionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttractAimComp = UMagnetDroneAttractAimComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPinballMagnetAttractionBossBallActivatedParams& Params) const
	{
		if(!HasControl())
			return false;

		if(!AttractionComp.IsInputtingAttract())
			return false;

		if(AttractionComp.IsAttracting())
			return false;

		if(AttractionComp.HasSetStartAttractTargetThisFrame())
			return false;

		if(!AttractAimComp.HasValidAimTarget())
			return false;

		if(!AttractAimComp.AimData.HasAutoAimTarget())
			return false;

		if(!AttractAimComp.AimData.GetAutoAimComp().IsA(UPinballBossAutoAimComponent))
			return false;

		auto PinballBoss = Cast<APinballBossBall>(AttractAimComp.AimData.GetActor());
		check(PinballBoss != nullptr);

		Params.AimData = AttractAimComp.AimData;

		Params.AimData.SetIsAbsoluteLocation(true);

		const FVector AutoAimLocation = Params.AimData.GetAutoAimComp().WorldLocation;

		const bool bPlayerIsOnRight = Player.ActorLocation.Y > AutoAimLocation.Y;

		FVector TargetNormal = bPlayerIsOnRight ? FVector::RightVector : FVector::LeftVector;
		Params.AimData.OverrideRelativeImpactNormal(TargetNormal);

		FVector WorldLocation = Params.AimData.GetAutoAimComp().WorldLocation + (TargetNormal * PinballBoss.Sphere.SphereRadius);
		const FVector RelativeLocation = WorldLocation - Params.AimData.GetTargetComp().WorldLocation;

		Params.AimData.OverrideRelativeLocation(RelativeLocation);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AttractionComp.HasFinishedAttracting())
			return true;

		if(!AttractionComp.HasAttractionTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPinballMagnetAttractionBossBallActivatedParams Params)
	{
		AttractionComp.SetStartAttractTarget(Params.AimData, EMagnetDroneStartAttractionInstigator::PinballBossBall);
	}
}