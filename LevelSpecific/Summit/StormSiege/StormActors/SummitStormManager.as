class ASummitStormManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6.0));

	UPROPERTY(EditAnywhere)
	AGameSky Sky;

	float FogDensity = 0.0;
	float FogTarget;

	float InterpSpeed = 0.25;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FogDensity = Math::FInterpConstantTo(FogDensity, FogTarget, DeltaSeconds, 0.25);
		Sky.ExponentialHeightFog.SetFogDensity(FogDensity);
	}

	UFUNCTION()
	void ActivateStormTransition(float InFogTarget, float NewInterpSpeed = 0.25)
	{
		SetActorTickEnabled(true);
		FogTarget = InFogTarget;
		InterpSpeed = NewInterpSpeed;
	}

	UFUNCTION()
	void SetStormFog(float InFogTarget)
	{
		FogTarget = InFogTarget;
		FogDensity = InFogTarget;
		Sky.ExponentialHeightFog.SetFogDensity(InFogTarget);
	}
}