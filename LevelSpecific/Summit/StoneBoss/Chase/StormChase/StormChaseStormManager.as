UCLASS(Abstract)
class AStormChaseStormManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(30.0));

	AGameSky Sky;

	UPROPERTY(EditAnywhere)
	FLinearColor LightningColour;
	FLinearColor StartColor;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	float MinRate = 5.0;
	float MaxRate = 10.0;
	float FireTime;

	UPROPERTY()
	bool bShowLightning;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Sky = TListedActors<AGameSky>().GetSingle();
		StartColor = Sky.Fog.Color;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > FireTime)
		{
			Game::Mio.PlayCameraShake(CameraShake, this, 0.45);
			Game::Zoe.PlayCameraShake(CameraShake, this, 0.45);
			FireTime = Time::GameTimeSeconds + Math::RandRange(MinRate, MaxRate);
			BP_ActivateLightning(Math::RandRange(0, 2));
		}

		if (bShowLightning)
			Sky.ExponentialHeightFog.SetFogInscatteringColor(LightningColour);
		else	
			Sky.ExponentialHeightFog.SetFogInscatteringColor(StartColor);
	}

	UFUNCTION()
	void ManualActivateLightning()
	{
		FireTime = 0.0;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateLightning(int Sequence) {}
}