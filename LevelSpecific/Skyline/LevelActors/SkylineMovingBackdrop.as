class ASkylineMovingBackdrop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent Spline;

	UPROPERTY(EditAnywhere)
	float Speed = 200.0;

	UPROPERTY(EditAnywhere)
	float Scale = 1.0;

	float Distance = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Root.WorldScale3D = FVector::OneVector * Scale;		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
//		Speed = Speed / Scale;
//		Root.WorldScale3D = FVector::OneVector * Scale;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Distance += Speed * DeltaSeconds;
		Distance = Math::Wrap(Distance, 0.0, Spline.SplineLength);
		FTransform RelativeTransform = Spline.GetRelativeTransformAtSplineDistance(Distance);
		RelativeTransform.Location = RelativeTransform.Location * Scale;
		FTransform InverseTransform = RelativeTransform.Inverse();
		SetActorLocationAndRotation(InverseTransform.Location, InverseTransform.Rotation);
	}
}