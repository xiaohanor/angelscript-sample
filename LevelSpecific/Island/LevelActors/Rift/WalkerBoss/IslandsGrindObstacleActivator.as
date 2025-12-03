class AIslandsGrindObstacleActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SparkComp;

	UPROPERTY(EditInstanceOnly)
	APropLine PropLineRef;
	UHazeSplineComponent Spline;
	float DistanceAlongSpline;

	FVector DestinationUpVector = FVector::UpVector;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 2;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PropLineRef == nullptr)
			return;

		Spline = Spline::GetGameplaySpline(PropLineRef);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		OnUpdate(0.0);

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));
		
		SparkComp.SetWorldLocationAndRotation(CurrentLocation, CurrentRotation);

	}

	UFUNCTION()
	void OnFinished()
	{
		BP_ReachedDestination();
	}

	UFUNCTION()
	void ObstacleActivated()
	{
		if (MoveAnimation.IsPlaying())
			return;

		if (MoveAnimation.Value == 1)
			return;

		MoveAnimation.PlayFromStart();
		BP_Activated();

	}
	
	UFUNCTION()
	void ObstacleDeactivated()
	{
		BP_Deactivated();
	}

	UFUNCTION()
	void ObstacleCompleted()
	{
		BP_Completed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activated() {}

	UFUNCTION(BlueprintEvent)
	void BP_ReachedDestination() {}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_Completed() {}
};