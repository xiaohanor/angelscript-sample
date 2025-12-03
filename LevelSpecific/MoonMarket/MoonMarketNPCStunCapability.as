class UMoonMarketNPCStunCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketNPCStunComponent StunComp;

	bool bIsStanding = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StunComp = UMoonMarketNPCStunComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(StunComp.StunDuration <= 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(StunComp.StunDuration <= 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StunComp.StunDuration -= DeltaTime;
	}
};