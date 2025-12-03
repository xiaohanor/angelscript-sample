class ACriclingDragon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	float RightOffset = 500.0;

	UPROPERTY(EditAnywhere)
	float ForwardOffset = 0.0;

	UHazeSplineComponent Spline;

	FSplinePosition SplinePos;

	float MoveSpeed = 1000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = SplineActor.Spline;
		SplinePos = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePos.Move(MoveSpeed * DeltaSeconds);
		ActorLocation = SplinePos.WorldLocation;
		ActorLocation += SplinePos.WorldRightVector * RightOffset;
		ActorLocation += SplinePos.WorldForwardVector * ForwardOffset;
		ActorRotation = SplinePos.WorldRotation.Rotator();
	}
};