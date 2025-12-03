class ASolarFlareMiningConveyerObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetHiddenInGame(true);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	FSplinePosition SplinePos;
	UHazeSplineComponent SplineComp;
	float StartingSplineDist;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplinePos = SplineComp.GetSplinePositionAtSplineDistance(StartingSplineDist);
	}

	void UpdateMove()
	{
		SetActorLocationAndRotation(SplinePos.WorldLocation, SplinePos.WorldRotation.Rotator());
	}
};