class AMeltdownBossPhaseThreeDissolveDome : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Dome;
	default Dome.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UBillboardComponent HoleLocation;

	FHazeTimeLike OpenHole;
	default OpenHole.Duration = 2.0;
	default OpenHole.UseSmoothCurveOneToZero();

//	UPROPERTY(EditAnywhere)
//	APlayerTrigger PTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Dome.SetVectorParameterValueOnMaterialIndex(0, n"Location", HoleLocation.WorldLocation);
		Dome.SetScalarParameterValueOnMaterialIndex(0, n"Radius", 0.0);

		OpenHole.BindUpdate(this, n"HoleOpening");

	//	PTrigger.OnPlayerEnter.AddUFunction(this, n"StartHole");
	}

	UFUNCTION()
	private void StartHole(AHazePlayerCharacter Player)
	{
		OpenHole.PlayFromStart();
	}

	UFUNCTION()
	private void HoleOpening(float CurrentValue)
	{
		Dome.SetScalarParameterValueOnMaterialIndex(0, n"Radius", Math::Lerp(1500,0,CurrentValue));
	}
};