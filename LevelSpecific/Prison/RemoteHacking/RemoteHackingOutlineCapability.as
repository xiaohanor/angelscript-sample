struct FRemoteHackingOutlineCapabilityActivationParams
{
	URemoteHackingResponseComponent HackingResponeComponent = nullptr;
}

class URemoteHackingOutlineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	URemoteHackingPlayerComponent RemoteHackingComp;
	UPlayerTargetablesComponent TargetablesComp;

	URemoteHackingResponseComponent CurrentResponseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RemoteHackingComp = URemoteHackingPlayerComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FRemoteHackingOutlineCapabilityActivationParams& ActivationParams) const
	{
		URemoteHackingResponseComponent TargetedHackingComp = Cast<URemoteHackingResponseComponent>(TargetablesComp.GetPrimaryTargetForCategory(n"RemoteHacking"));
		if (TargetedHackingComp == nullptr)
			return false;

		ActivationParams.HackingResponeComponent = TargetedHackingComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		URemoteHackingResponseComponent TargetedHackingComp = Cast<URemoteHackingResponseComponent>(TargetablesComp.GetPrimaryTargetForCategory(n"RemoteHacking"));
		if (TargetedHackingComp == nullptr)
			return true;

		if (TargetedHackingComp != CurrentResponseComp)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FRemoteHackingOutlineCapabilityActivationParams ActivationParams)
	{
		CurrentResponseComp = ActivationParams.HackingResponeComponent;

		UOutlineDataAsset OutlineData = CurrentResponseComp.OutlineData == nullptr ? RemoteHackingComp.OutlineAsset : CurrentResponseComp.OutlineData;

		TArray<UPrimitiveComponent> PrimitiveComps;
		CurrentResponseComp.Owner.GetComponentsByClass(UPrimitiveComponent, PrimitiveComps);
		TArray<UPrimitiveComponent> OutlineComps = PrimitiveComps;
		for (UPrimitiveComponent Comp : PrimitiveComps)
		{
			if (CurrentResponseComp.CompsToExcludeFromOutline.Contains(Comp.Name))
				OutlineComps.Remove(Comp);
		}

		Outline::ApplyOutlineOnComponents(OutlineComps, Player, OutlineData, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(CurrentResponseComp))
			Outline::ClearOutlineOnActor(CurrentResponseComp.Owner, Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}