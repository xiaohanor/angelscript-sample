event void FIslandEntranceFlyingVechileSignature();

class AIslandEntranceFlyingVechile : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BobbingRoot;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;
	float DistanceAlongSpline;
	
	UPROPERTY(EditAnywhere)
	float TravelDuration = 1.0;

	UPROPERTY(EditAnywhere)
	bool bShouldRotate = false;

	UPROPERTY(EditAnywhere)
	FVector DestinationUpVector = FVector::UpVector;

	UPROPERTY()
	FIslandEntranceFlyingVechileSignature OnReachedDestination;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float BobHeight = 1.0;

	UPROPERTY(EditAnywhere)
	float BobSpeed = 10.0;

	UPROPERTY(EditAnywhere)
	float BobOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			OnUpdate(0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = SplineActor.Spline;
		OnUpdate(0.0);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0 / TravelDuration);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BobbingRoot.SetRelativeLocation(FVector::UpVector * Math::Sin((Time::GameTimeSeconds * BobSpeed + BobOffset)) * BobHeight);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = TransformAtDistance.Rotation;
			
		// FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));
		// if (Alpha < 0.99)
		SetActorLocation(CurrentLocation);
		if(bShouldRotate)
		{
			SetActorRotation(CurrentRotation);
		}

		// SetActorLocationAndRotation(CurrentLocation, CurrentRotation);
	}

	UFUNCTION()
	void OnFinished()
	{
		OnReachedDestination.Broadcast();
	}

	UFUNCTION()
	void Activate()
	{
		MoveAnimation.Play();
	}

	UFUNCTION()
	void Deactivate()
	{
		MoveAnimation.Stop();
	}

}