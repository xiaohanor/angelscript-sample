class AEvergreenRotationRootBoulder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent TheRoots;

	UPROPERTY(DefaultComponent, Attach = TheRoots)
	UStaticMeshComponent Boulder;

	UPROPERTY(DefaultComponent, Attach = Boulder)
	USceneComponent VFXSpawnLocation;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager LifeManager;

	UPROPERTY(EditAnywhere)
	bool bReverseRotation;

	bool bLayingDown = false;

	FRotator NewRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if (LifeManager.LifeComp.RawHorizontalInput > 0.25)
			bLayingDown = true;
		else if (LifeManager.LifeComp.RawHorizontalInput < -0.25)
			bLayingDown = false;

		NewRotation = Math::RInterpConstantShortestPathTo(RotationRoot.RelativeRotation, bLayingDown ? FRotator(0, 0, 90) : FRotator(0, 0, 0), DeltaSeconds, 200);
		RotationRoot.SetRelativeRotation(NewRotation);
	}
};