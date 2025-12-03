UCLASS(Abstract, HideCategories = "Actor Cooking")
class ASkylineCarChaseTraffic : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Trigger;
	default Trigger.BoxExtent = FVector(200.0, 4000.0, 4000.0);
	default Trigger.bBlockCollisionOnDisable = false;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarImpactResponseComponent ImpactResponseComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent VelocityTrackerComponent;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = false;

	UPROPERTY(EditInstanceOnly)
	AActorTrigger ActorTrigger;

	UPROPERTY(EditInstanceOnly)
	AActor SplineToFollow;

	UPROPERTY(EditAnywhere)
	float DesiredSpeed = 5000.0;

	UPROPERTY(EditAnywhere)
	float AccelerationMultiplier = 1.0;

	float CurrentSpeed = 0.0;

	UPROPERTY(EditAnywhere)
	bool bWrapMovement = false;

	UPROPERTY(EditAnywhere)
	bool bBrakeToStopAtSplineEnd = true;

	UPROPERTY(EditAnywhere)
	bool bBigShip = false;

	bool bIsDestroyed = false;

	UPROPERTY(EditAnywhere)
	bool bDestroyeAtEnd = true;

	
	UPROPERTY(EditAnywhere)
	float StopAtDistanceFromEnd = 0.0;

	UPROPERTY(EditAnywhere)
	float StopAtDistance = 0.0;

	float TravelDistance = 0.0;

	UPROPERTY(EditAnywhere)
	FVector BobbingSpeed = FVector(1.0, 0.5, 2.0);

	UPROPERTY(EditAnywhere)
	FVector BobbingDistance = FVector(50.0, 50.0, 100.0);

	FHazeAcceleratedFloat BobbingAlpha;

	FVector OffsetFromSpline;

	FSplinePosition SplinePosition;
	FSplinePosition InitialSplinePosition;

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
			if (ActorTrigger != nullptr)
				Trigger.SetVisibility(false);
			else
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
		// else
		// 	Print("NoSplineActor: " + this);
	}

#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ActorTrigger != nullptr)
		{
			ActorTrigger.ActorClasses.AddUnique(ASkylineFlyingCar);
			ActorTrigger.OnActorEnter.AddUFunction(this, n"OnActorTriggered");		
		}
		else
		{
			Trigger.OnComponentBeginOverlap.AddUFunction(this, n"OnTriggered");
		}

		if (SplineToFollow != nullptr)
			Spline = Spline::GetGameplaySpline(SplineToFollow, this);
	
		if (Spline != nullptr)
		{
			SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
			InitialSplinePosition = SplinePosition;
			OffsetFromSpline = SplinePosition.WorldTransformNoScale.InverseTransformPositionNoScale(ActorLocation);
		}

		Update();

		if (bStartActivated)
		{
			Activate();
		}
		else
		{
			// Don't disable, we sill want visibility
			AddActorTickBlock(this);
		}

		ImpactResponseComp.OnImpactedByFlyingCar.AddUFunction(this, n"OnImpactedByFlyingCar");
		ImpactResponseComp.OnImpactedByCarEnemy.AddUFunction(this, n"OnImpactedByCarEnemy");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BobbingAlpha.AccelerateTo(1.0, 2.0, DeltaSeconds);

		if (bStartActivated && bWrapMovement)
		{
			// Special case for cars just moving across a looping spline permanently to stay in sync
			float LoopedSplineDistance = Math::Wrap(
				InitialSplinePosition.CurrentSplineDistance + (Time::PredictedGlobalCrumbTrailTime * DesiredSpeed),
				0.0, SplinePosition.CurrentSpline.SplineLength);
			SplinePosition = FSplinePosition(SplinePosition.CurrentSpline, LoopedSplineDistance, SplinePosition.IsForwardOnSpline());

			Update();
		}
		else
		{
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

			if (bBrakeToStopAtSplineEnd && SplinePosition.CurrentSplineDistance >= SplinePosition.CurrentSpline.SplineLength && bDestroyeAtEnd)
				DestroyCar();

			Update();
		}
	}

	UFUNCTION()
	private void OnImpactedByFlyingCar(ASkylineFlyingCar FlyingCar, FFlyingCarOnImpactData ImpactData)
	{
		/**
		 * In BP, we also check if the impactor is the player car, and if so, we explode.
		 * TODO: Needs to be revisited.
		 */
		USkylineCarChaseTrafficEffectEventHandler::Trigger_OnExploded(this);
		FlyingCar.Gunner.PlayCameraShake(FlyingCar.LightCollisionCameraShake, this);
		FlyingCar.Pilot.PlayCameraShake(FlyingCar.LightCollisionCameraShake, this);
		BP_OnImpactedByFlyingCar(FlyingCar, ImpactData);
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnImpactedByFlyingCar(ASkylineFlyingCar FlyingCar, FFlyingCarOnImpactData ImpactData) {}

	UFUNCTION()
	private void OnImpactedByCarEnemy(ASkylineFlyingCarEnemy CarEnemy, FFlyingCarOnImpactData ImpactData)
	{
		if(!bBigShip)
		{
			ExplodeCar(ImpactData.ImpactPoint);
			AddActorCollisionBlock(this);
		}
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
	private void OnTriggered(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto FlyingCar = Cast<ASkylineFlyingCar>(OtherActor);
		if (FlyingCar == nullptr)
			return;

		Activate();
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorTickBlock(this);
		Trigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void DestroyCar()
	{
		if(!bIsDestroyed)
		{
			bIsDestroyed = true;
			DestroyActor();
		}
	}

	UFUNCTION(BlueprintEvent)
	void ExplodeCar(FVector ImpactPoint) {}
}

UCLASS(Abstract)
class USkylineCarChaseTrafficEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExploded() {};
}