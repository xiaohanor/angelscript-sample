class AHoverDumpster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DumpsterRoot;

	UPROPERTY(DefaultComponent, Attach = DumpsterRoot)
	UStaticMeshComponent DumpsterMesh;
	default DumpsterMesh.RelativeScale3D = FVector(0.5);

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	FSplinePosition SplinePos;

	float MoveSpeed = 1000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplinePos = FSplinePosition(SplineActor.Spline, 0.0, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SplinePos.Move(MoveSpeed * DeltaTime);
		SetActorLocationAndRotation(SplinePos.WorldLocation, SplinePos.WorldRotation);
	}
}