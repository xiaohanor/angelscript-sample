class ASanctuaryLightBirdChaser : ASanctuaryDynamicPerchSpline
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	ULightBirdChaserComponent LightBirdChaserComponent;

	UPROPERTY(DefaultComponent, Attach = LightBirdChaserComponent)
	UDarkPortalTargetComponent DarkPortalTargetComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	default Spline.SplinePoints.Reset();
	default Spline.SplinePoints.Add(FHazeSplinePoint(FVector(-200.0, 0.0, 0.0)));
	default Spline.SplinePoints.Add(FHazeSplinePoint(FVector(50.0, 0.0, 0.0)));
	default Spline.SplinePoints.Add(FHazeSplinePoint(FVector(50.0, 0.0, 0.0)));

	int StartPoint;
	int EndPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StartPoint = Spline.SplinePoints.Num() - 2;
		EndPoint = Spline.SplinePoints.Num() - 1;

		Spline.SplinePoints[StartPoint].RelativeLocation = FVector::ZeroVector;
		Spline.SplinePoints[StartPoint].bOverrideTangent = true;
		Spline.SplinePoints[EndPoint].bOverrideTangent = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LightBirdChaserComponent.Update(DeltaSeconds);

		Spline.SplinePoints[StartPoint].LeaveTangent = Spline.WorldTransform.InverseTransformVectorNoScale(ActorForwardVector * 800.0);
//		Spline.SplinePoints[StartPoint].LeaveTangent = Spline.WorldTransform.InverseTransformVectorNoScale(Spline.WorldLocation - LightBirdChaserComponent.WorldLocation);

		Spline.SplinePoints[EndPoint].RelativeLocation = Spline.WorldTransform.InverseTransformPositionNoScale(LightBirdChaserComponent.WorldLocation);
		Spline.SplinePoints[EndPoint].ArriveTangent = Spline.WorldTransform.InverseTransformVectorNoScale(LightBirdChaserComponent.ForwardVector * Spline.SplineLength);

		Super::Tick(DeltaSeconds);
	}
}