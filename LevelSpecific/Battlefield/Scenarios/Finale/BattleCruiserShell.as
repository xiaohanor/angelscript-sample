class ABattleCruiserShell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UHazeSplineComponent SplineComp;

	FSplinePosition SplinePos;
	float CurrentDistance = 0.0;
	float SpeedTarget = 5000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplinePos = SplineComp.GetSplinePositionAtSplineDistance(CurrentDistance);
		ActorRotation = SplinePos.GetWorldRotation().Rotator();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.AddLocalRotation(FRotator(-360.0 * DeltaSeconds, 0.0, 0.0));
		SplinePos.Move(SpeedTarget * DeltaSeconds);
		ActorLocation = SplinePos.WorldLocation;

		if (SplinePos.CurrentSplineDistance == SplineComp.SplineLength)
		{
			DestroyActor();
		}
	}
}