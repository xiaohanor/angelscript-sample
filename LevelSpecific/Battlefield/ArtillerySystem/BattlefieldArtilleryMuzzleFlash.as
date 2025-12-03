class ABattlefieldArtilleryMuzzleFlash : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent MuzzleFlash;
	default MuzzleFlash.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent LightComp;
	default LightComp.SetIntensity(0.0);

	float LightIntensity = 500.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LightComp.SetIntensity(Math::FInterpConstantTo(LightComp.Intensity, 0.0, DeltaSeconds, LightIntensity * 2.0));
	}

	UFUNCTION()
	void FireMuzzle(float Delay)
	{
		Timer::SetTimer(this, n"TimedMuzzleFlash", Delay);
	}

	UFUNCTION()
	void TimedMuzzleFlash()
	{
		LightComp.SetIntensity(LightIntensity);
		MuzzleFlash.Activate();
	}
}