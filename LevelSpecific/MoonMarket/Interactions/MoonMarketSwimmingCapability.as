class UMoonMarketSwimmingCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketPlayerInteractionComponent InteractComp;
	UPlayerSwimmingComponent SwimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InteractComp = UMoonMarketPlayerInteractionComponent::Get(Player);
		SwimComp = UPlayerSwimmingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SwimComp.ActiveSwimmingVolumes.IsEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SwimComp.IsSwimming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(int i = InteractComp.CurrentInteractions.Num() -1; i >= 0; i--)
		{
			if(Cast<AMoonMarketHoldableActor>(InteractComp.CurrentInteractions[i]) != nullptr)
				InteractComp.CurrentInteractions[i].StopInteraction(Player);
		}

		if(UPlayerFireworksComponent::Get(Player).FireworkRocket != nullptr)
			UPlayerFireworksComponent::Get(Player).CancelFirework();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};