class ACrystalGrowthSplineMover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UCrystalGrowthKillComponent KillComp;

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 1000.0;

	FSplinePosition SplinePos;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = Spline.Spline;
		SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePos.Move(MoveSpeed * DeltaSeconds);
		ActorLocation = SplinePos.WorldLocation;
		// ActorRotation = SplinePos.WorldRotation.RightVector.Rotation();
		// ActorRotation = SplinePos.WorldRotation.Rotator();
		ActorRotation = FRotator::MakeFromZX(SplinePos.WorldRotation.RightVector, SplinePos.WorldRotation.ForwardVector);
	}
};