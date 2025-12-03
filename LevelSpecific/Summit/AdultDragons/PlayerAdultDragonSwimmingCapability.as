class UPlayerAdultDragonSwimmingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	UPlayerSwimmingComponent SwimmingComp;
	UPlayerAdultDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		SwimmingComp = UPlayerSwimmingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwimmingComp.IsSwimming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwimmingComp.IsSwimming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.AnimParams.bIsSwimming = true;
		UPlayerAdultDragonSwimmingEventHandler::Trigger_EnterWater(DragonComp.AdultDragon, FPlayerAdultDragonSwimmingData(DragonComp.AdultDragon.Mesh));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimParams.bIsSwimming = false;
		UPlayerAdultDragonSwimmingEventHandler::Trigger_ExitWater(DragonComp.AdultDragon, FPlayerAdultDragonSwimmingData(DragonComp.AdultDragon.Mesh));
	}
};