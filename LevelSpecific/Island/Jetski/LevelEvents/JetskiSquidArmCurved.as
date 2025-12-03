class AJetskiSquidArmCurved : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;
	
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = Mesh01)
	UStaticMeshComponent Mesh02;
	default Mesh02.RelativeRotation = FRotator(-45.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = Mesh02)
	UStaticMeshComponent Mesh03;
	default Mesh03.RelativeRotation = FRotator(-45.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = Mesh03)
	UStaticMeshComponent Mesh04;
	default Mesh04.RelativeRotation = FRotator(-45.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	bool bShouldBeHiddenBeforeSwing = false;

	UPROPERTY(EditAnywhere)
	float InterpSpeed = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bShouldBeHiddenBeforeSwing)
			SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Mesh03.SetRelativeRotation(Math::QInterpConstantTo(Mesh03.RelativeRotation.Quaternion(), Mesh02.RelativeRotation.Quaternion(), DeltaSeconds, InterpSpeed));
		Mesh04.SetRelativeRotation(Math::QInterpConstantTo(Mesh04.RelativeRotation.Quaternion(), Mesh03.RelativeRotation.Quaternion(), DeltaSeconds, InterpSpeed));
	}

	UFUNCTION()
	void StartStraightenArm()
	{
		if(bShouldBeHiddenBeforeSwing)
			SetActorHiddenInGame(false);

		OnArmStartedToStraighten();
	}

	UFUNCTION(BlueprintEvent)
	void OnArmStartedToStraighten(){}
}