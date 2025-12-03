class ASkylineMovingBackdropManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float Speed = 1000.0;

	float Distance = 0.0;

	UPROPERTY(EditAnywhere)
	TArray<ASkylineMovingBackdropSegment> Segments;

	UPROPERTY(EditAnywhere)
	int ActiveAdjacentSegments = 1;

	int CurrentSegmentIndex = 0;

	FVector InactiveSegmentOffset = FVector::UpVector * - 10000.0;

	FQuat Rotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Rotation = ActorQuat;

		for (int i = 0; i < Segments.Num(); i++)
			Segments[i].Root.SetRelativeLocation(InactiveSegmentOffset);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Distance += Speed * DeltaSeconds;

		if (Distance > Segments[CurrentSegmentIndex].Spline.SplineLength)
		{
			Distance -= Segments[CurrentSegmentIndex].Spline.SplineLength;

			Rotation *= Segments[CurrentSegmentIndex].RelativeEndTransform.Inverse().Rotation;

			CurrentSegmentIndex = Math::WrapIndex(CurrentSegmentIndex + 1, -1, Segments.Num());
			Segments[Math::WrapIndex(CurrentSegmentIndex - ActiveAdjacentSegments - 1, 0, Segments.Num())].Root.SetRelativeLocation(InactiveSegmentOffset);	
		}

		FTransform RelativeTransform = Segments[CurrentSegmentIndex].Spline.GetRelativeTransformAtSplineDistance(Distance);
		FTransform InverseTransform = RelativeTransform.Inverse();

		FQuat LerpedRotation = FQuat::Slerp(Segments[CurrentSegmentIndex].Root.RelativeRotation.Quaternion(), InverseTransform.Rotation, DeltaSeconds * 5.0);
		FVector LerpedLocation = Math::Lerp(Segments[CurrentSegmentIndex].Root.RelativeLocation, InverseTransform.Location, DeltaSeconds * 5.0);

		Segments[CurrentSegmentIndex].Root.SetRelativeLocationAndRotation(LerpedLocation, LerpedRotation);
//		Segments[CurrentSegmentIndex].Root.SetRelativeLocationAndRotation(InverseTransform.Location, InverseTransform.Rotation);

		for (int i = 1; i <= ActiveAdjacentSegments; i++)
		{
			FTransform NextTransform = Segments[CurrentSegmentIndex + (i - 1)].RelativeEndTransform * Segments[CurrentSegmentIndex + (i - 1)].Root.RelativeTransform;
			Segments[Math::WrapIndex(CurrentSegmentIndex + i, -1, Segments.Num())].Root.SetRelativeLocationAndRotation(NextTransform.Location, NextTransform.Rotation);

			FTransform PrevTransform = Segments[Math::WrapIndex(CurrentSegmentIndex - i, 0, Segments.Num())].RelativeEndTransform.Inverse() * Segments[Math::WrapIndex(CurrentSegmentIndex - (i - 1), 0, Segments.Num())].Root.RelativeTransform;
			Segments[Math::WrapIndex(CurrentSegmentIndex - i, 0, Segments.Num())].Root.SetRelativeLocationAndRotation(PrevTransform.Location, PrevTransform.Rotation);
		}

		Root.SetRelativeRotation(Rotation * InverseTransform.Rotation);
	}
}