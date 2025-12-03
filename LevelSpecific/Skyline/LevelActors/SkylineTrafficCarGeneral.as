class ASkylineTrafficCarGeneral : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	default AddActorTag(FlyingCarTags::FlyingCarTraffic);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Trigger;
	default Trigger.BoxExtent = FVector(200.0, 300.0, 400.0);

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeComp;

	UPROPERTY(DefaultComponent, Attach = ConeComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent CarMesh;
	
	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = false;

	UPROPERTY(EditAnywhere)
	AActor TriggeringActor;

	UPROPERTY(EditInstanceOnly)
	AActor SplineToFollow;

	UPROPERTY(EditAnywhere)
	float DesiredSpeed = 11800.0;

	UPROPERTY(EditAnywhere)
	float AccelerationMultiplier = 1.0;

	float CurrentSpeed = 0.0;

	UPROPERTY(EditAnywhere)
	bool bWrapMovement = true;

	UPROPERTY()
	bool bBrakeToStopAtSplineEnd = false;

	UPROPERTY()
	float StopAtDistanceFromEnd = 0.0;

	UPROPERTY()
	float StopAtDistance = 0.0;
	
	float TravelDistance = 0.0;

	UPROPERTY(EditAnywhere)
	FVector BobbingSpeed = FVector(1.0, 0.5, 2.0);

	UPROPERTY(EditAnywhere)
	FVector BobbingDistance = FVector(50.0, 50.0, 100.0);

	FHazeAcceleratedFloat BobbingAlpha;

	FVector OffsetFromSpline;

	FSplinePosition SplinePosition;

	UHazeSplineComponent Spline;

#if EDITOR

	UPROPERTY(EditAnywhere)
	float TriggerDistance = 8000.0;

	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<AHazeActor> PlaceTriggerOnSpline;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (!Editor::IsCooking())
		{
			Editor_SetTriggerLocation();
		}			
	}

	private void Editor_SetTriggerLocation()
	{
		Trigger.SetVisibility(true);

		if (PlaceTriggerOnSpline.IsValid())
		{
			auto SplineComp = UHazeSplineComponent::Get(PlaceTriggerOnSpline.Get());
			if (SplineComp != nullptr && SplineComp.ComputedSpline.IsValid())
			{
				float SplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);

				FTransform SplineTransform = SplineComp.GetWorldTransformAtSplineDistance(SplineDistance - TriggerDistance);

				Trigger.SetWorldLocationAndRotation(SplineTransform.Location, SplineTransform.Rotation);
			}
		}
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
		else
			Print("NoSplineActor: " + this);
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

		ASkylineTrafficLight TrafficLightActivator = Cast <ASkylineTrafficLight>(TriggeringActor);

		TrafficLightActivator.TrafficStop.AddUFunction(this, n"HandleStopCar");
				
	
		Update();


		if (bStartActivated)
			Activate();
	}



	UFUNCTION(BlueprintEvent)
	private void HandleStopCar(){}



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
			SplinePosition = SplinePosition.CurrentSpline.GetSplinePositionAtSplineDistance(0.0);

		Update();
	}

	float GetThrustForce() property
	{
		float Thrust = DesiredSpeed;

		if (CurrentSpeed < DesiredSpeed)
			Thrust *= AccelerationMultiplier;

		

		if (StopAtDistance > 0.0 && TravelDistance > StopAtDistance - CurrentSpeed)
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

	
}