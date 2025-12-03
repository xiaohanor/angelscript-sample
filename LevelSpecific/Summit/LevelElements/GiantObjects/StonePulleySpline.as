class AStonePulleySpline : ASplineActor
{
	UPROPERTY(EditAnywhere)
	APulleyInteraction PulleyInteraction1;

	UPROPERTY(EditAnywhere)
	APulleyInteraction PulleyInteraction2;

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 940.0;

	FHazeAcceleratedFloat AccelMoveAmount;
	float CurrentDistance;
	float SpeedTarget;
	float DistanceFromCenter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// RollingWheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolled");
		TargetActor.ActorLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(TargetActor.ActorLocation);
		CurrentDistance = Spline.GetClosestSplineDistanceToWorldLocation(TargetActor.ActorLocation);
		AccelMoveAmount.SnapTo(0.0);
	
		// PulleyInteraction1.OnSummitPulleyPulling.AddUFunction(this, n"OnSummitPulleyPulling1");
		// PulleyInteraction2.OnSummitPulleyPulling.AddUFunction(this, n"OnSummitPulleyPulling2");
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

		DistanceFromCenter = CurrentDistance - (Spline.GetSplineLength() / 2.0);
		// PrintToScreen("DistanceFromCenter: " + DistanceFromCenter);
	}

	UFUNCTION()
	private void OnWheelRolled(float Amount)
	{
		if (Amount > 0.0)
			SpeedTarget = MoveSpeed; 
		else
			SpeedTarget = -MoveSpeed;
	}
	
	UFUNCTION()
	private void OnSummitPulleyPulling1(float Force)
	{
		SpeedTarget = Force;
	}

	UFUNCTION()
	private void OnSummitPulleyPulling2(float Force)
	{
		SpeedTarget = -Force;
	}
}