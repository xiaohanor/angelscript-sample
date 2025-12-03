class UMoonMarketMushroomPotionCapability : UMoonMarketPlayerShapeshiftCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UMoonMarketMushroomPotionComponent MushroomComp;
	AHazeActor Mushroom;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UMoonMarketPlayerShapeshiftCapability::Setup();
		MushroomComp = UMoonMarketMushroomPotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnActivated();

		Mushroom = ShapeshiftInto(MushroomComp.MushroomClass);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnDeactivated();

		Mushroom.DestroyActor();
		Mushroom = nullptr;
		RemoveVisualBlocker();
	}
};