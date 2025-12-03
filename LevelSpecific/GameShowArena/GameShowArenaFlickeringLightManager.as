enum EGameShowLightGlitchIntensity
{
	Low,
	Medium,
	High,
	MAX
}

class AGameShowArenaFlickeringLightManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(EditInstanceOnly)
	AHazePostProcessVolume PostProcessVolume;

	EGameShowLightGlitchIntensity CurrentLightGlitchIntensity;

	private TArray<AGameShowArenaFlickeringLight> Internal_Lights;
	private TArray<AGameShowArenaSpotlight> Internal_Spotlights;

	UPROPERTY(EditInstanceOnly)
	TArray<UCurveFloat> FlickerCurves;
	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor GameshowAdMonitors;
	

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentLightGlitchIntensity = EGameShowLightGlitchIntensity::High;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		for(auto Light : Lights)
		{
			if(Light == nullptr)
				continue;

			Light.RecieveFlickerValue(Time::GameTimeSeconds, CurrentLightGlitchIntensity);
		}

		HandlePostProcess();
		HandleGlitchyAds();

		if(CurrentLightGlitchIntensity == EGameShowLightGlitchIntensity::Low)
			return;
		
		for(auto Spotlight : Spotlights)
		{
			if(Spotlight == nullptr)
				continue;

			Spotlight.RecieveFlickerValue(Time::GameTimeSeconds, CurrentLightGlitchIntensity);
		}
	}

	void HandlePostProcess()
	{
		float Alpha = (Time::GameTimeSeconds) % 7;
		float NewBrightness = Math::Lerp(1.3, 1, FlickerCurves[CurrentLightGlitchIntensity].GetFloatValue(Alpha));
		float NewVignetteIntensity = Math::Lerp(0.4, 0.4, FlickerCurves[CurrentLightGlitchIntensity].GetFloatValue(Alpha));
		
		PostProcessVolume.Settings.AutoExposureMaxBrightness = NewBrightness;
		PostProcessVolume.Settings.AutoExposureMinBrightness = NewBrightness;
		PostProcessVolume.Settings.VignetteIntensity = NewVignetteIntensity;
	}

	void HandleGlitchyAds()
	{
		float Alpha = (Time::GameTimeSeconds) % 7;
		float NewGlitchLevel = Math::Lerp(1.0, 0.0, FlickerCurves[CurrentLightGlitchIntensity].GetFloatValue(Alpha));
		GameshowAdMonitors.StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(0, n"glitchAmount", NewGlitchLevel);

		float GlitchTilingAlpha = Math::Sin(Time::GetGameTimeSeconds());
		float NewGlitchTiling = Math::Lerp(2.0, 4.0, Math::Abs(GlitchTilingAlpha));
		GameshowAdMonitors.StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(0, n"glitchTiling", NewGlitchTiling);
	}

	UFUNCTION()
	void SetLightsEnabled(bool bEnabled)
	{
		for(auto Light : Lights)
			Light.EnableLight(bEnabled);

		for(auto Spotlight : Spotlights)
			Spotlight.EnableLight(bEnabled);

		float AdsFadeValue = bEnabled ? 1.0 : 0.0;
		GameshowAdMonitors.StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(0, n"Fade", AdsFadeValue);
	}

	UFUNCTION()
	void StartFlickerLights(EGameShowLightGlitchIntensity FlickerIntensity)
	{
		CurrentLightGlitchIntensity = FlickerIntensity;
		SetActorTickEnabled(true);

		GameshowAdMonitors.StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(0, n"Fade", 1.0);
	}

	UFUNCTION()
	void StopFlickerLights(bool bShouldRemainOn)
	{
		SetActorTickEnabled(false);

		for(auto Light : Lights)
			Light.EnableLight(bShouldRemainOn);

		for(auto Spotlight : Spotlights)
			Spotlight.EnableLight(bShouldRemainOn);

		PostProcessVolume.Settings.AutoExposureMaxBrightness = 1;
		PostProcessVolume.Settings.AutoExposureMinBrightness = 1;
		PostProcessVolume.Settings.VignetteIntensity = 0.4;

		GameshowAdMonitors.StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(0, n"glitchAmount", 0.0);
		GameshowAdMonitors.StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(0, n"glitchTiling", 4.0);

		float AdsFadeValue = bShouldRemainOn ? 1.0 : 0.0;
		GameshowAdMonitors.StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(0, n"Fade", AdsFadeValue);
	}

	private TArray<AGameShowArenaFlickeringLight> GetLights() property
	{
		if(!Internal_Lights.IsEmpty())
			return Internal_Lights;

		Internal_Lights = TListedActors<AGameShowArenaFlickeringLight>().GetArray();
		return Internal_Lights;
	}

	private TArray<AGameShowArenaSpotlight> GetSpotlights() property
	{
		if(!Internal_Spotlights.IsEmpty())
			return Internal_Spotlights;

		Internal_Spotlights = TListedActors<AGameShowArenaSpotlight>().GetArray();
		return Internal_Spotlights;
	}	
};