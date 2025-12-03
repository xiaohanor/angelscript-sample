struct FSkylineAllyTrafficJamCarBreakParams
{
	UPROPERTY()
	float Speed;

	UPROPERTY()
	float BreakDistance;
}

UCLASS(Abstract)
class USkylineAllyTrafficJamCarEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDriving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartBreaking(FSkylineAllyTrafficJamCarBreakParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedBreaking() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInitialStateCompleted() {}
}

event void FSkylineTrafficJamOnStoppedBreaking();

class USkylineAllyTrafficJamAudioParamComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	int QueuePosition = 0;

	UPROPERTY()
	float InverseDistanceAlongSpline = 0.0;
}

class ASkylineAllyTrafficJamCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent CarPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float DriveSpeed = 3000.0;

	UPROPERTY(EditAnywhere)
	float BreakDistance = 1000.0;

	UPROPERTY(EditAnywhere)
	float BobbingDuration = 2.0;

	UPROPERTY(EditAnywhere)
	float BobbingDistance = 100.0;

	UPROPERTY(EditInstanceOnly)
	int QueuePosition = 0;

	UPROPERTY()
	FSkylineTrafficJamOnStoppedBreaking OnStoppedBreaking;

	FVector BobbingOffset;

	float InverseDistanceAlongSpline = 0.0;

	float Speed;

	bool bTriggered = false;

	bool bStartedBreaking = false;
	
	bool bFinishedBreaking = false;

	UPROPERTY(EditInstanceOnly)
	bool bCrashingCar = false;

	AHazePrefabActor CarPrefabActor;

	USkylineAllyTrafficJamAudioParamComponent AudioParamComp;

	FHazeTimeLike BobbingTimeLike;
	default BobbingTimeLike.UseSmoothCurveZeroToOne();
	default BobbingTimeLike.bFlipFlop = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BobbingTimeLike.Duration = BobbingDuration;

		BobbingTimeLike.BindUpdate(this, n"BobbingTimeLikeUpdate");

		SetActorTickEnabled(false);

		Speed = DriveSpeed;

		InverseDistanceAlongSpline = SplineComp.SplineLength;

		CarPivotComp.SetWorldLocationAndRotation(SplineComp.GetWorldLocationAtSplineDistance(InverseDistanceAlongSpline), 
												SplineComp.GetWorldRotationAtSplineDistance(InverseDistanceAlongSpline));

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, bRecursivelyIncludeAttachedActors = true);
		for (auto AttachedActor : AttachedActors)
		{
			auto AttachedCar = Cast<AHazePrefabActor>(AttachedActor);	

			if (AttachedCar != nullptr)
			{
				CarPrefabActor = AttachedCar;

				AudioParamComp = USkylineAllyTrafficJamAudioParamComponent::Get(CarPrefabActor);
			}
		}
	}

	UFUNCTION()
	private void BobbingTimeLikeUpdate(float CurrentValue)
	{
		BobbingOffset = FVector::UpVector * (CurrentValue - 0.5) * BobbingDistance;
	}

	UFUNCTION()
	void StartDriving()
	{
		if (bTriggered)
			return;

		//BobbingTimeLike.Play();

		SetActorTickEnabled(true);
		bTriggered = true;

		USkylineAllyTrafficJamCarEventHandler::Trigger_OnStartDriving(CarPrefabActor);
	}

	UFUNCTION()
	void StartEnabled()
	{
		CarPivotComp.SetWorldLocationAndRotation(SplineComp.GetWorldLocationAtSplineDistance(0), 
												SplineComp.GetWorldRotationAtSplineDistance(0));
		bTriggered = true;

		USkylineAllyTrafficJamCarEventHandler::Trigger_OnInitialStateCompleted(CarPrefabActor);
	}

	UFUNCTION()
	private void StartBreaking()
	{
		bStartedBreaking = true;

		FSkylineAllyTrafficJamCarBreakParams Params;
		Params.BreakDistance = BreakDistance;
		Params.Speed = DriveSpeed;

		USkylineAllyTrafficJamCarEventHandler::Trigger_OnStartBreaking(CarPrefabActor, Params);
	}

	UFUNCTION()
	private void FinishedBreaking()
	{
		if (bCrashingCar)
		{
			CarPivotComp.ApplyImpulse(CarPivotComp.WorldLocation + FVector::UpVector * 100.0, ActorForwardVector * 50.0);
			OnStoppedBreaking.Broadcast();
		}

		bFinishedBreaking = true;

		USkylineAllyTrafficJamCarEventHandler::Trigger_OnFinishedBreaking(CarPrefabActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector NewLocation = SplineComp.GetWorldLocationAtSplineDistance(InverseDistanceAlongSpline) + BobbingOffset;
		FQuat NewRotation = SplineComp.GetWorldRotationAtSplineDistance(InverseDistanceAlongSpline);

		CarPivotComp.SetWorldLocationAndRotation(NewLocation, NewRotation);

		InverseDistanceAlongSpline -= Speed * DeltaSeconds;

		if (AudioParamComp != nullptr)
			AudioParamComp.InverseDistanceAlongSpline = InverseDistanceAlongSpline;

		if (bCrashingCar)
		{
			if (InverseDistanceAlongSpline <= 0.0 && !bFinishedBreaking)
			{
				StartBreaking();
				FinishedBreaking();
				InverseDistanceAlongSpline = 0.0;
			}
		}

		else if (InverseDistanceAlongSpline < BreakDistance && !bFinishedBreaking)
		{
			if (!bStartedBreaking)
				StartBreaking();

			Speed = InverseDistanceAlongSpline / BreakDistance * DriveSpeed;

			if (InverseDistanceAlongSpline < 5.0)
			{
				FinishedBreaking();
			}
		} 
	}
};