class AStormSiegeLightning : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;

	UPROPERTY(EditAnywhere)
	TArray<AActor> LocationPoints;

	UPROPERTY(EditAnywhere)
	ASplineActor BuildUpLightingSpline;

	int Index = 0;

	float LightningTime;
	float LightningInterval = 2.5;
	UPROPERTY(EditAnywhere)
	float DelayTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightningTime = Time::GameTimeSeconds + DelayTime;

		if (BuildUpLightingSpline != nullptr)
			UNiagaraComponent::Get(BuildUpLightingSpline).Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > LightningTime)
		{
			LightningTime = Time::GameTimeSeconds + LightningInterval;
			ActivateLightning();
		}
	}

	void ActivateLightning()
	{
		if (BuildUpLightingSpline != nullptr)
		{
			FStormLightningSplineEffectParams Params;
			Params.LightningNiagaraComp = UNiagaraComponent::Get(BuildUpLightingSpline);
			Params.BuildUpAlpha = 1.0;
			Params.Width = 1.0;
			UStormSiegeLightningEffectsHandler::Trigger_ActivateSpline(this, Params);

			Timer::SetTimer(this, n"LightningFire", 1.0 / Params.BuildUpAlpha);
		}
		else
		{
			LightningFire();
		}

		Index++;
		if (Index > LocationPoints.Num() - 1)
			Index = 0;
	}

	UFUNCTION()
	void LightningFire()
	{
		if (LocationPoints.Num() == 0)
			return;
		
		FStormSiegeLightningStrikeParams LightningParams;
		LightningParams.Start = ActorLocation;
		LightningParams.End = LocationPoints[Index].ActorLocation;
		LightningParams.BeamWidth = 1.0;
		FStormSiegeRockImpactParams RockParams;
		RockParams.Location = LocationPoints[Index].ActorLocation;
		RockParams.Direction = LocationPoints[Index].ActorForwardVector;

		UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(this, LightningParams);
		UStormSiegeLightningEffectsHandler::Trigger_RockImpact(this, RockParams);
	}
}