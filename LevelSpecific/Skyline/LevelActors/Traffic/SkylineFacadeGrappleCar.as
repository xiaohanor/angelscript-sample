event void FSkylineFacadeGrappleCarSplineStartSignature();

class ASkylineFacadeGrappleCar : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = false;

	UPROPERTY(EditInstanceOnly)
	AActor SplineToFollow;

	UPROPERTY(EditAnywhere)
	float DesiredSpeed = 2000.0;

	UPROPERTY(EditAnywhere)
	float AccelerationMultiplier = 1.0;

	float CurrentSpeed = 0.0;

	bool bWrapMovement = true;

	bool bBrakeToStopAtSplineEnd = false;
	float StopAtDistanceFromEnd = 0.0;
	float StopAtDistance = 0.0;

	UPROPERTY(EditAnywhere)
	float StopAtDistanceOffset;

	float TravelDistance = 0.0;

	UPROPERTY(EditAnywhere)
	FVector BobbingSpeed = FVector(1.0, 0.5, 2.0);

	UPROPERTY(EditAnywhere)
	FVector BobbingDistance = FVector(10.0, 10.0, 20.0);

	FHazeAcceleratedFloat BobbingAlpha;

	UPROPERTY(EditAnywhere)
	ASwingPoint SwingPoint;

	FVector OffsetFromSpline;

	FSplinePosition SplinePosition;

	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY()
	bool bShouldBreak = false;

	UPROPERTY(EditAnywhere)
	bool bIsFacadeCar = true;

	UPROPERTY()
	FSkylineFacadeGrappleCarSplineStartSignature OnStartOnSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	

		if (SplineToFollow != nullptr)
			Spline = Spline::GetGameplaySpline(SplineToFollow, this);
	
		if (Spline != nullptr)
		{
			SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
			OffsetFromSpline = SplinePosition.WorldTransformNoScale.InverseTransformPositionNoScale(ActorLocation);
		}

		
	
		Update();


		if (bStartActivated)
			Activate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BobbingAlpha.AccelerateTo(1.0, 2.0, DeltaSeconds);

		float Acceleration = ThrustForce
						   - CurrentSpeed * 1.0;

		CurrentSpeed += Acceleration * DeltaSeconds;

		float DeltaMove = CurrentSpeed * DeltaSeconds;

		TravelDistance += DeltaMove;

		if(!SplinePosition.Move(DeltaMove))
		{
			if(!bWrapMovement && !bBrakeToStopAtSplineEnd)
			{
				AddActorDisable(this);
				return;
			}
		}	

		if (bWrapMovement && SplinePosition.CurrentSplineDistance >= SplinePosition.CurrentSpline.SplineLength)
		{
			InterfaceComp.TriggerActivate();
			SplinePosition = SplinePosition.CurrentSpline.GetSplinePositionAtSplineDistance(0.0);
			OnStartOnSpline.Broadcast();
		}

		if(bIsFacadeCar)
		{
			if (SplinePosition.CurrentSplineDistance > 0.0 && SplinePosition.CurrentSplineDistance < 6000.0)
				SetSlowSpeed();

			if (SplinePosition.CurrentSplineDistance > 6000 && SplinePosition.CurrentSplineDistance < 10000.0)
				ResetSpeed();

			if (SplinePosition.CurrentSplineDistance > 11000.0 && SplinePosition.CurrentSplineDistance < 16000.0)
				SetSlowSpeed();
			
			if (SplinePosition.CurrentSplineDistance > 17000.0)
				ResetSpeed();
		}

		if(!bIsFacadeCar)
		{
			if (SplinePosition.CurrentSplineDistance > 9000.0 && SplinePosition.CurrentSplineDistance < 17000.0)
				SetSlowSpeed();

			if (SplinePosition.CurrentSplineDistance > 17000 && SplinePosition.CurrentSplineDistance < 50000.0)
				ResetSpeed();

			if (SplinePosition.CurrentSplineDistance > 54000.0 && SplinePosition.CurrentSplineDistance < 59000.0)
				SetSlowSpeed();

			if (SplinePosition.CurrentSplineDistance > 60000)
				ResetSpeed();

		}

		Update();

		PrintToScreen("Distance:" + SplinePosition.CurrentSplineDistance);
	}

	float GetThrustForce() property
	{
		float Thrust = DesiredSpeed;

		if (CurrentSpeed < DesiredSpeed)
			Thrust *= AccelerationMultiplier;

		if (bBrakeToStopAtSplineEnd && SplinePosition.CurrentSpline.SplineLength - StopAtDistanceFromEnd - SplinePosition.CurrentSplineDistance <= CurrentSpeed)
			Thrust = -CurrentSpeed;

		if (StopAtDistance > 0.0 && TravelDistance > StopAtDistance - CurrentSpeed)
			Thrust = -CurrentSpeed;

		if(SplinePosition.GetCurrentSplineDistance() > 16000 - StopAtDistanceOffset && SplinePosition.GetCurrentSplineDistance() < 24000 && bShouldBreak)
			Thrust = -CurrentSpeed;

		return Thrust;
	}

	void Update()
	{
		FTransform Transform = SplinePosition.WorldTransformNoScale;
		Transform.Location = Transform.Location + Transform.TransformVectorNoScale(OffsetFromSpline + BobbingOffset);

		SetActorLocationAndRotation(Transform.Location, Transform.Rotation);
	}

	FVector GetBobbingOffset() const property
	{
		FVector Offset;
		Offset.X = Math::Sin((Time::GameTimeSeconds + OffsetFromSpline.Size()) * BobbingSpeed.X) * BobbingDistance.X;
		Offset.Y = Math::Sin((Time::GameTimeSeconds + OffsetFromSpline.Size()) * BobbingSpeed.Y) * BobbingDistance.Y;
		Offset.Z = Math::Sin((Time::GameTimeSeconds + OffsetFromSpline.Size()) * BobbingSpeed.Z) * BobbingDistance.Z;
	
		return Offset * BobbingAlpha.Value;
	}

	UFUNCTION()
	void Activate()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void GoodByeCars()
	{
		bWrapMovement = false;

		if(SplinePosition.GetCurrentSplineDistance() < 40000)
		{
			TArray<AActor> Cars;
			GetAttachedActors(Cars);
			for(auto Car : Cars)
			{
				Car.AddActorDisable(this);
			}
			AddActorDisable(this);
		}
			
	}


	UFUNCTION(DevFunction)
	void ShouldBreak()
	{
		bShouldBreak = true;
	}

	UFUNCTION(DevFunction)
	void ShouldStart()
	{
		bShouldBreak = false;
		DesiredSpeed = 3000;
		Timer::SetTimer(this, n"ResetSpeed", 5.0);
	}

	private void SetSlowSpeed()
	{
		if(bIsFacadeCar)
		{
			DesiredSpeed = 1000;
		}else
		{
			DesiredSpeed = 600;
		}
		
	}

	UFUNCTION()
	private void ResetSpeed()
	{
		if(bIsFacadeCar)
		{
			DesiredSpeed = 2500;
		}else
		{
			DesiredSpeed = 4000;
		}
		


	}
}