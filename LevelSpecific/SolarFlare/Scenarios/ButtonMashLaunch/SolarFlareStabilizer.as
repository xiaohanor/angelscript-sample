class ASolarFlareStabilizer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot; 

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLight;
	default SpotLight.SetIntensity(5.0);
	default SpotLight.SetUseInverseSquaredFalloff(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ChargeUpSystem;
	default ChargeUpSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SteamSystem;
	default ChargeUpSystem.SetAutoActivate(false);

	float LightIntensity;
	float CurrentLightIntensity;
	FHazeAcceleratedFloat AcceleratedCurrentProgress;
	float TargetProgress;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChargeUpSystem.SetNiagaraVariableFloat("Alpha", 0.0);
		LightIntensity = SpotLight.Intensity;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedCurrentProgress.AccelerateTo(TargetProgress, 1.0, DeltaSeconds);
		CurrentLightIntensity = LightIntensity * AcceleratedCurrentProgress.Value;
		SpotLight.SetIntensity(CurrentLightIntensity);
	}
	
	void UpdateChargeUpProgress(float Progress)
	{
		TargetProgress = Progress;
		ChargeUpSystem.SetNiagaraVariableFloat("Alpha", Progress);
	}

	void FinishSequence()
	{
		SteamSystem.Activate();
	}

	UFUNCTION()
	void ActivateBigLaser()
	{
		BP_BigBoomLaser();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BigBoomLaser() {}

	UFUNCTION()
	void DeactivateBigLaser()
	{
		SpotLight.SetIntensity(0.0);
		BP_DeactivateBigBoomLaser();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateBigBoomLaser() {}
};