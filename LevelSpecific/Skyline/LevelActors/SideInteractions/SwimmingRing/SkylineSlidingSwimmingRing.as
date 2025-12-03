class ASkylineSlidingSwimmingRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComponent;

	UPROPERTY(EditInstanceOnly)
	ASplineActor MoveSpline;

	float SplineDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//todo(ylva) after summer :3
		SetActorHiddenInGame(true);
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (MoveSpline != nullptr)
		{
			SplineDistance += 500.0 * DeltaSeconds;
			SplineDistance = Math::Wrap(SplineDistance, 0.0, MoveSpline.Spline.SplineLength);
			FTransform Transform = MoveSpline.Spline.GetWorldTransformAtSplineDistance(SplineDistance);
			SetActorLocationAndRotation(Transform.Location, Transform.Rotator());
		}
	}
};