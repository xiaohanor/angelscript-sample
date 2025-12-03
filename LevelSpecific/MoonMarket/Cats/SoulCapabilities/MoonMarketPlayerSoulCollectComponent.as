class UMoonMarketPlayerSoulCollectComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence Animation; 

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset PlayerCameraSettings;

	bool bIsCollectingSoul;
	AMoonMarketCat TargetCat;

	TArray<AMoonMarketCat> CurrentCats;

	void StartCatCollection(AMoonMarketCat NewCat)
	{
		TargetCat = NewCat;
		bIsCollectingSoul = true;
		CurrentCats.AddUnique(NewCat);

		FMoonMarketCatEventParams Params;
		Params.NewTotalCats = CurrentCats.Num();

		for(auto Cat : CurrentCats)
		{
			UMoonMarketCatEventHandler::Trigger_OnCatTotalUpdated(Cat, Params);
		}
	}

	void RemoveCat(AMoonMarketCat CatToRemove)
	{
		CurrentCats.Remove(CatToRemove);

		FMoonMarketCatEventParams Params;
		Params.NewTotalCats = CurrentCats.Num();

		for(auto Cat : CurrentCats)
		{
			UMoonMarketCatEventHandler::Trigger_OnCatTotalUpdated(Cat, Params);
		}
	}
};