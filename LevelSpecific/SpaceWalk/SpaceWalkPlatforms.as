class ASpaceWalkPlatforms : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BobbingRoot;

	UPROPERTY(DefaultComponent , Attach = BobbingRoot)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent , Attach = TranslateComp)
	UFauxPhysicsConeRotateComponent RotationComp;

	UPROPERTY(DefaultComponent, Attach = RotationComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent , Attach = Mesh)
	UFauxPhysicsSpringConstraint SpringComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeight;

	UPROPERTY(EditAnywhere)
	float BobHeight = 50.0;

	UPROPERTY(EditAnywhere)
	float BobSpeed = 2.0;

	UPROPERTY(EditAnywhere)
	float BobOffset = 0.0;

	float Bob;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BobbingRoot.SetRelativeLocation(FVector::UpVector * Math::Sin((Time::GameTimeSeconds * BobSpeed + BobOffset)) * BobHeight);
	}
	
};