
class ADynamicWaterEffectCutsceneOverride : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere, Interp)
	float SimulationSizeOverride = 5000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Sky = GetSky();
		if (Sky == nullptr)
			return;

		Sky.DynamicWaterEffectControllerComponent.bSimulationSizeOverride = true;
		Sky.DynamicWaterEffectControllerComponent.SimulationSizeOverrideValue = SimulationSizeOverride;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Sky = GetSky();
		if (Sky == nullptr)
			return;

		Sky.DynamicWaterEffectControllerComponent.SimulationSizeOverrideValue = SimulationSizeOverride;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto Sky = GetSky();
		if (Sky == nullptr)
			return;
		
		Sky.DynamicWaterEffectControllerComponent.bSimulationSizeOverride = false;
	}
	
}