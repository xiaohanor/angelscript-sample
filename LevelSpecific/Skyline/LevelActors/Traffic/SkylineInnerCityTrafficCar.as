class ASkylineInnerCityTrafficCar : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = false;

	UPROPERTY(EditInstanceOnly)
	AActor SplineToFollow;

	UPROPERTY(EditAnywhere)
	float DesiredSpeed = 5000.0;

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
	FVector BobbingDistance = FVector(50.0, 50.0, 100.0);

	FHazeAcceleratedFloat BobbingAlpha;

	FVector OffsetFromSpline;

	FSplinePosition SplinePosition;

	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY()
	bool bShouldBreak = false;

#if EDITOR

	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<AHazeActor> PlaceTriggerOnSpline;

	private void Editor_SetTriggerLocation()
	{
		

		if (SplineToFollow != nullptr)
		{
			auto SplineComp = UHazeSplineComponent::Get(SplineToFollow);
			if (SplineComp != nullptr && SplineComp.ComputedSpline.IsValid())
			{
				float SplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);

				FTransform SplineTransform = SplineComp.GetWorldTransformAtSplineDistance(SplineDistance);

				ActorRotation = SplineTransform.Rotation.Rotator();
			}
		}
		// else
		// 	Print("NoSplineActor: " + this);
	}

#endif

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
		}			

		Update();

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
	private void OnActorTriggered(AHazeActor Actor)
	{
		auto FlyingCar = Cast<ASkylineFlyingCar>(Actor);
		if (FlyingCar == nullptr)
			return;

		Activate();	
	}


	UFUNCTION()
	void Activate()
	{
		SetActorTickEnabled(true);
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
		DesiredSpeed = 9000;
		Timer::SetTimer(this, n"ResetSpeed", 5.0);
	}

	UFUNCTION()
	private void ResetSpeed()
	{
		DesiredSpeed = 5000;
	}
}