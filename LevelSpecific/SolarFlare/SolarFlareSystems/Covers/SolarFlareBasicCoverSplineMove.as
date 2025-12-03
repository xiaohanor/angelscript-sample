class ASolarFlareBasicCoverSplineMove : ASolarFlareBasicCover
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	USolarFlareSplineMoveComponent SplineMoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineMoveComp.OnSolarFlareSplineMoveCompStartMoving.AddUFunction(this, n"OnSolarFlareSplineMoveCompStartMoving");	
		SplineMoveComp.OnSolarFlareSplineMoveCompStopMoving.AddUFunction(this, n"OnSolarFlareSplineMoveCompStopMoving");	
		WaveReactComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		FSolarFlareBasicCoverParams Params;
		Params.Location = ActorLocation;
		USolarFlareBasicCoverSplineMoverEffectHandler::Trigger_OnWaveImpact(this, Params);
	}

	UFUNCTION()
	private void OnSolarFlareSplineMoveCompStartMoving()
	{
		FSolarFlareBasicCoverParams Params;
		Params.Location = ActorLocation;
		Params.bMovingUp = SplineMoveComp.Direction < 0;
		USolarFlareBasicCoverSplineMoverEffectHandler::Trigger_OnStartMoving(this, Params);
	}

	UFUNCTION()
	private void OnSolarFlareSplineMoveCompStopMoving()
	{
		FSolarFlareBasicCoverParams Params;
		Params.Location = ActorLocation;
		Params.bMovingUp = SplineMoveComp.Direction < 0;
		USolarFlareBasicCoverSplineMoverEffectHandler::Trigger_OnStopMoving(this, Params);
	}
}