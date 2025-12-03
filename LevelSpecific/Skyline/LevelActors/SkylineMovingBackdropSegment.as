class ASkylineMovingBackdropSegment : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent Spline;

	FTransform RelativeEndTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RelativeEndTransform.Location = Spline.SplinePoints.Last().RelativeLocation;
		RelativeEndTransform.Rotation = Spline.SplinePoints.Last().RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}
}