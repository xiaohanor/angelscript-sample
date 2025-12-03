class AShuttleSceneSplineFollow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float MoveSpeedTarget = 5000.0;
	float CurrentMoveSpeed;

	FSplinePosition SplinePos;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = Spline.Spline;
		SplinePos = SplineComp.GetSplinePositionAtSplineDistance(0.0);
		ActorLocation = SplinePos.WorldLocation;
		CurrentMoveSpeed = MoveSpeedTarget * 2.0;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentMoveSpeed = Math::FInterpConstantTo(CurrentMoveSpeed, MoveSpeedTarget, DeltaSeconds, MoveSpeedTarget / 4.0);
		SplinePos.Move(CurrentMoveSpeed * DeltaSeconds);
		ActorLocation = SplinePos.WorldLocation;
		ActorRotation = SplinePos.WorldRotation.Rotator();
	}

	UFUNCTION()
	void ActivateSplineMovement()
	{
		SetActorTickEnabled(true);
	}
}