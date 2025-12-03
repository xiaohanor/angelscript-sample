class ASnapBackPulleySpline : ASplineActor
{
	UPROPERTY(EditAnywhere)
	APulleyInteraction PulleyInteraction;

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	float ReturnSpeedTarget = 1000;
	UPROPERTY(EditAnywhere)
	float ReturnSpeedAcceleration = 700.0;

	UPROPERTY(EditAnywhere)
	float Bounciness = 0.2;

	UPROPERTY(EditAnywhere)
	bool bInvertMoveDirection = false;

	float BounceThreshold = 100.0;

	float ReturnSpeed;
	float StartDistance;
	float CurrentDistance;
	float TargetDistanceSpeed;
	float DistanceFromCenter;

	// int Direction;

	bool bPulleyActive;
	bool bStopped;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// RollingWheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolled");
		TargetActor.ActorLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(TargetActor.ActorLocation);
		CurrentDistance = Spline.GetClosestSplineDistanceToWorldLocation(TargetActor.ActorLocation);
		StartDistance = CurrentDistance;
	
		PulleyInteraction.OnSummitPulleyPulling.AddUFunction(this, n"OnSummitPulleyPulling");

		// if (bInvertMoveDirection)
		// 	Direction = 1.0;
		// else
		// 	Direction = -1.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!PulleyInteraction.bIsPulling)
		{
			if (!bStopped)
			{
				ReturnSpeed = Math::FInterpConstantTo(ReturnSpeed, ReturnSpeedTarget, DeltaTime, ReturnSpeedAcceleration);

				CurrentDistance += ReturnSpeed * DeltaTime;

				if (bInvertMoveDirection)
					CurrentDistance = Math::Clamp(CurrentDistance, 0.0, StartDistance);
				else
					CurrentDistance = Math::Clamp(CurrentDistance, StartDistance, Spline.GetSplineLength());

				if (CurrentDistance == StartDistance)
				{
					if (Math::Abs(ReturnSpeed) > BounceThreshold)
					{
						ReturnSpeed = -ReturnSpeed * Bounciness;
					}
					else
					{
						bStopped = true;
						ReturnSpeed = 0.0;
					}
				}
			}
		}
		else
		{
			CurrentDistance += TargetDistanceSpeed * DeltaTime;
			bStopped = false;
			ReturnSpeed = 0.0;
		}

		TargetActor.ActorLocation = Spline.GetWorldLocationAtSplineDistance(CurrentDistance);

		// TargetActor.ActorLocation = Spline.GetWorldLocationAtSplineDistance(CurrentDistance);
		// TargetActor.ActorRotation = Spline.GetWorldRotationAtSplineDistance(CurrentDistance).Rotator();
		// SpeedTarget = 0.0;

		// DistanceFromCenter = CurrentDistance - (Spline.GetSplineLength() / 2.0);
		// PrintToScreen("DistanceFromCenter: " + DistanceFromCenter);

		// PulleyInteraction.SetObjectDistanceFromCenter(StartDistance - CurrentDistance);

		TargetDistanceSpeed = 0.0;
	}
	
	UFUNCTION()
	private void OnSummitPulleyPulling()
	{
		// if (bInvertMoveDirection)
		// 	CurrentDistance = Force;
		// else
		// TargetDistanceSpeed = Force;
	}
}