class USummitEggPlacingCompoundCapability : UHazeCompoundCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	default DebugCategory = SummitDebugCapabilityTags::EggBackpack;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USummitEggBackpackComponent BackpackComp;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
			.Then(n"SummitEggPlacingCapability")
			.Then(n"SummitEggPlacedCapability")
			.Then(n"SummitEggPickUpCapability")
		;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BackpackComp = USummitEggBackpackComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BackpackComp.bPlacementRequested)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BackpackComp.bResetRequested)
			return true;

		if(!BackpackComp.CurrentEggHolder.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}
}