class ACounterWeightTranslate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UFauxPhysicsTranslateComponent TranslateRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UBillboardComponent EndComp;
	default EndComp.SetWorldScale3D(FVector(6.0));

	UPROPERTY(EditAnywhere, Category = "Setup")
	ANightQueenMetal Metal;

	// UPROPERTY(EditAnywhere, Category = "Setup")
	// bool bMetalWeightAttached = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector DownForce = FVector(0.0, 0.0, -2000.0);

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector UpForce = FVector(0.0, 0.0, 2000.0);

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bInvertForceDirection = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		Metal.OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
		ForceComp.Force = bInvertForceDirection ? DownForce : UpForce;
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		ForceComp.Force = bInvertForceDirection ? UpForce : DownForce;
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		ForceComp.Force = bInvertForceDirection ? DownForce : UpForce;
	}
}