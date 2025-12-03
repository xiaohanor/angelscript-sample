class AEvergreenSlopeObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent Cylinder;

	UPROPERTY(DefaultComponent, Attach = Cylinder)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent ShootLoc;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager Manager;

	float HorizontalInput;

	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		HorizontalInput = Manager.LifeComp.RawHorizontalInput;
		FRotator NewRotation;
		TargetRotation = FRotator(HorizontalInput * 40, RotationRoot.RelativeRotation.Yaw, RotationRoot.RelativeRotation.Roll);
		NewRotation = Math::RInterpConstantShortestPathTo(RotationRoot.RelativeRotation, TargetRotation, DeltaSeconds, 40);
		RotationRoot.SetRelativeRotation(NewRotation);
	}
};