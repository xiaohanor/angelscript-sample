class ASolarFlareGreenhouseLocomotive : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp, ShowOnActor)
	USolarFlarePlayerCoverComponent CoverComp;
	default CoverComp.Distance = 500.0;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USolarFlareSplineMoveComponent SplineMoveComp;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent SolarFlareReactComp;

	//TODO Add effect comp and effect components to actor

	UPROPERTY(EditAnywhere)
	bool bDebugPrint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SolarFlareReactComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
		SplineMoveComp.OnSolarFlareSplineMoveCompStopMoving.AddUFunction(this, n"OnSolarFlareSplineMoveCompStopMoving");
		SplineMoveComp.OnSolarFlareSplineMoveCompStartMoving.AddUFunction(this, n"OnSolarFlareSplineMoveStartMoving");
	}

	UFUNCTION()
	private void OnSolarFlareSplineMoveStartMoving()
	{
		if (bDebugPrint)
			Print("" + Name + " OnSolarFlareSplineMoveStartMoving");

		FSolarFlareGreenhouseLocomotiveNextSplineMoveEffectParams Params;
		Params.StopLocation = ActorLocation;
		USolarFlareGreenhouseLocomotiveEffectHandler::Trigger_OnGreenhouseLocomotiveStartNextSplineMove(this, Params);
	}

	UFUNCTION()
	private void OnSolarFlareSplineMoveCompStopMoving()
	{
		if (bDebugPrint)
			Print("" + Name + " OnSolarFlareSplineMoveCompStopMoving");

		FSolarFlareGreenhouseLocomotiveNextSplineMoveEffectParams Params;
		Params.StopLocation = ActorLocation;
		USolarFlareGreenhouseLocomotiveEffectHandler::Trigger_OnGreenhouseLocomotiveStopSplineMove(this, Params);
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