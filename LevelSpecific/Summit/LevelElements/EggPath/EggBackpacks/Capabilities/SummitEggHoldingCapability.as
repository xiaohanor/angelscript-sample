class USummitEggHoldingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(EggBackpackCapabilityTags::EggBackpack);
	default TickGroupOrder = 90;

	default TickGroup = EHazeTickGroup::Gameplay;

	default DebugCategory = SummitDebugCapabilityTags::EggBackpack;

	ASummitEggBackpack Backpack;
	USummitEggBackpackComponent BackpackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BackpackComp = USummitEggBackpackComponent::Get(Player);
		BackpackComp.bIsHoldingEgg = false;
		Backpack = BackpackComp.Backpack;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BackpackComp.CurrentEggHolder.IsSet())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BackpackComp.CurrentEggHolder.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BackpackComp.bIsHoldingEgg = true;
		Backpack.PlaySlotAnimation(BackpackComp.BackpackUnplacedAnim);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BackpackComp.bIsHoldingEgg = false;
	}
};