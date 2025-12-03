#if EDITOR

class USpotModeDetails : UHazeScriptDetailCustomization
{
	default DetailClass = USpotSoundComponent;

	bool bHideSettings = false;
	
	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"HazeSpotSoundComponent", ("Spot Sound Data"));
		// EditCategory(n"SpotSoundComponent",("Spot Sound Data"));

		auto Spot = Cast<USpotSoundComponent>(GetCustomizedObject());
		bHideSettings = !Spot.UseDefaultSettings();

		if (bHideSettings)
			HideProperty(n"Settings");
		else
			AddDefaultPropertiesFromOtherCategory(n"HazeSpotSoundComponent", n"SpotSoundComponent");

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		auto Spot = Cast<USpotSoundComponent>(GetCustomizedObject());

		if (Spot == nullptr)
			return;

		bool bHideSettingsNow = !Spot.UseDefaultSettings();
		if (bHideSettings != bHideSettingsNow)
		{
			bHideSettings = bHideSettingsNow;
			ForceRefresh();
		}
	}
}

#endif