class AWheelPulleySpline : ASplineActor
{
	UPROPERTY(EditAnywhere)
	ASummitRollingWheel RollingWheel;

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 940.0;

	FHazeAcceleratedFloat AccelMoveAmount;
	float CurrentDistance;
	float SpeedTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// RollingWheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolled");
		TargetActor.ActorLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(TargetActor.ActorLocation);
		CurrentDistance = Spline.GetClosestSplineDistanceToWorldLocation(TargetActor.ActorLocation);
		AccelMoveAmount.SnapTo(0.0);
	}

	UFUNCTION()
	private void OnWheelRolled(float Amount)
	{
		if (Amount > 0.0)
			SpeedTarget = MoveSpeed;
		else
			SpeedTarget = -MoveSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AccelMoveAmount.AccelerateTo(SpeedTarget, 3.0, DeltaTime);
		CurrentDistance += AccelMoveAmount.Value * DeltaTime;
		CurrentDistance = Math::Clamp(CurrentDistance, 0.0, Spline.GetSplineLength());
		TargetActor.ActorLocation = Spline.GetWorldLocationAtSplineDistance(CurrentDistance);
		TargetActor.ActorRotation = Spline.GetWorldRotationAtSplineDistance(CurrentDistance).Rotator();
		SpeedTarget = 0.0;
	}
}