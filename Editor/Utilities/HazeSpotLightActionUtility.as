class UHazeSpotLightActionUtility : UHazeLightActionUtility
{
	default SupportedClasses.Add(ASpotLight);

	UFUNCTION(CallInEditor, Category = "Static Light Actions")
    void SelectStaticSpotLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ASpotLight), EComponentMobility::Static);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectStationarySpotLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ASpotLight), EComponentMobility::Stationary);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectShadowCastingStationarySpotLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ASpotLight), EComponentMobility::Stationary, true);
	}

	UFUNCTION(CallInEditor, Category = "Movable Light Actions")
    void SelectMovableSpotLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ASpotLight), EComponentMobility::Movable);
	}
}
