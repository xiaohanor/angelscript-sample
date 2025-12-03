class ASummitRollingPulleySpline : ASplineActor
{
	UPROPERTY(Category = "Setup", EditAnywhere)
	ASummitRollingWheel Wheel;

	UPROPERTY(Category = "Setup", EditAnywhere)
	AActor TargetActor;

	UPROPERTY(Category = "Settings", EditAnywhere)
	float MovementMultiplier = 15.0;

	float CurrentDistance;
	float MaxDistance;

	FHazeAcceleratedFloat AccelDistance;
	float TargetDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentDistance = Spline.GetClosestSplineDistanceToWorldLocation(TargetActor.ActorLocation);
		TargetActor.ActorLocation = Spline.GetWorldLocationAtSplineDistance(CurrentDistance);
		MaxDistance = Spline.GetSplineLength();

		AccelDistance.SnapTo(CurrentDistance);

		Wheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolled");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AccelDistance.AccelerateTo(TargetDistance, 3.5, DeltaTime);
		CurrentDistance += AccelDistance.Value * DeltaTime;
		CurrentDistance = Math::Clamp(CurrentDistance, 0.0, MaxDistance);
		
		if (TargetActor != nullptr)
			TargetActor.ActorLocation = Spline.GetWorldLocationAtSplineDistance(CurrentDistance);
		
		TargetDistance = 0.0;
	}

	UFUNCTION()
	private void OnWheelRolled(float Amount)
	{
		TargetDistance = Amount * MovementMultiplier;
	}
}