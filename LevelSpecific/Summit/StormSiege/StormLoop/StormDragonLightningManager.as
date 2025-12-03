class AStormDragonLightningManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(10.0);

	UPROPERTY(EditAnywhere)
	AStormDragonIntro StormDragon;

	UPROPERTY(EditAnywhere)
	TArray<APointLight> PointLights;

	UPROPERTY(EditAnywhere)
	AGameSky Sky;

	UPROPERTY(EditAnywhere)
	AHazeSphere HazeSphere;

	UPROPERTY(EditAnywhere)
	FLinearColor LightningColour;
	FLinearColor StartColor;

	float LightningRate = 4.5;
	float LightingTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightingTime = Time::GameTimeSeconds + 2.0;

		for (APointLight Light : PointLights)
		{
			Light.LightComponent.SetHiddenInGame(true);
		}

		StormDragon.Mesh.SetHiddenInGame(true);
		HazeSphere.SetActorHiddenInGame(true);

		SetActorTickEnabled(false);

		StartColor = Sky.Fog.Color;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > LightingTime)
		{
			LightingTime = Time::GameTimeSeconds + LightningRate;
			BP_StartLightningReveal();
		}
	}

	UFUNCTION()
	void ActivateLightningManager()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartLightningReveal() {}

	UFUNCTION()
	void SetLightningDragonReveal(bool bShow)
	{
		for (APointLight Light : PointLights)
		{
			if (bShow)
				Light.LightComponent.SetHiddenInGame(false);
			else	
				Light.LightComponent.SetHiddenInGame(true);
		}

		if (bShow)
			Sky.ExponentialHeightFog.SetFogInscatteringColor(LightningColour);
		else	
			Sky.ExponentialHeightFog.SetFogInscatteringColor(StartColor);

		HazeSphere.SetActorHiddenInGame(!bShow);
		StormDragon.Mesh.SetHiddenInGame(!bShow);
	}
}