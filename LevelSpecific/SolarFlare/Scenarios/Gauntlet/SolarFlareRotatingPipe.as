class ASolarFlareRotatingPipe : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	int RotateDirection = 1;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 90.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.AddLocalRotation(FRotator(0,0,RotationSpeed * RotateDirection * DeltaSeconds));
	}
};