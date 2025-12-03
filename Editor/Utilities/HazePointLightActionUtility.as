class UHazePointLightActionUtility : UHazeLightActionUtility
{
	default SupportedClasses.Add(APointLight);

	UFUNCTION(CallInEditor, Category = "Static Light Actions")
    void SelectStaticPointLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(APointLight), EComponentMobility::Static);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectStationaryPointLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(APointLight), EComponentMobility::Stationary);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectShadowCastingStationaryPointLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(APointLight), EComponentMobility::Stationary, true);
	}

	UFUNCTION(CallInEditor, Category = "Movable Light Actions")
    void SelectMovablePointLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(APointLight), EComponentMobility::Movable);
	}
}
