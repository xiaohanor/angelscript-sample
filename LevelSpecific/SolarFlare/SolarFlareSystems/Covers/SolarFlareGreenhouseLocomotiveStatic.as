class ASolarFlareGreenhouseLocomotiveStatic : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USolarFlarePlayerCoverComponent CoverComp;
	default CoverComp.Distance = 500.0;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent SolarFlareReactComp;

	UPROPERTY(EditAnywhere)
	bool bDebugPrint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SolarFlareReactComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		if (bDebugPrint)
			Print("" + Name + " OnSolarFlareImpact");

		FSolarFlareGreenhouseLocomotiveSolarFlareImpactEffectParams Params;
		Params.ImpactLocation = ActorLocation;
		USolarFlareGreenhouseLocomotiveEffectHandler::Trigger_OnGreenhouseLocomotiveSolarFlareImpact(this, Params);
	}
}