class UMoonMarketPolymorphPotionCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketPolymorphPotionComponent PolymorphPotionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PolymorphPotionComp = UMoonMarketPolymorphPotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(PolymorphPotionComp.bIsTransformed)
		{
			PolymorphPotionComp.Unmorph();
		}
		else
		{
			PolymorphPotionComp.Morph();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto PotionComp = UMoonMarketPotionInteractionComponent::Get(Player);
		PotionComp.StopCurrentInteraction();
	}
};