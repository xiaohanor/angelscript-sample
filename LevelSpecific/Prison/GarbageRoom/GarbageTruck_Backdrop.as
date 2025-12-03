
event void FGarbageTruck_BackDrop_StoppedForGarbageEvent();

UCLASS(Abstract)
class AGarbageTruck_Backdrop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TruckRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent FrontLeftThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent FrontRightThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent BackLeftThrusterRoot;

	UPROPERTY(DefaultComponent, Attach = TruckRoot)
	USceneComponent BackRightThrusterRoot;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UPROPERTY()
	FGarbageTruck_BackDrop_StoppedForGarbageEvent OnStoppedForGarbage;

	UPROPERTY()
	FGarbageTruckEvent OnReachedEndOfSpline;
	bool bReachedEnd = false;

	FSplinePosition SplinePos;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 1250.0;

	UPROPERTY(EditAnywhere)
	bool bMoving = true;

	UPROPERTY(EditInstanceOnly)
	bool bPreviewPosition = false;
	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewFraction = 0.0;

	UPROPERTY(EditInstanceOnly)
	bool bResetOnEnd = true;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike StopForGarbageTimeLike;
	bool bStoppedForGarbage = false;
	bool bStoppedForGarbageThisCycle = false;

	UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float StopForGarbageFraction = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewPosition)
		{
			FTransform PreviewTransform = SplineActor.Spline.GetWorldTransformAtSplineDistance(SplineActor.Spline.SplineLength * PreviewFraction);
			FRotator Rot = FRotator(PreviewTransform.Rotation);
			Rot.Pitch = Math::Clamp(Rot.Pitch, -8.0, 8.0);
			SetActorLocationAndRotation(PreviewTransform.Location, Rot);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor != nullptr)
		{
			SplinePos = FSplinePosition(SplineActor.Spline, SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation), true);

			if (bMoving)
				UGarbageTruck_BackDropEffectEventHandler::Trigger_Reset(this);
		}

		StopForGarbageTimeLike.BindUpdate(this, n"UpdateStopForGarbage");
		StopForGarbageTimeLike.BindFinished(this, n"FinishStopForGarbage");
	}

	void StopForGarbage()
	{
		bStoppedForGarbage = true;
		bStoppedForGarbageThisCycle = true;

		StopForGarbageTimeLike.PlayFromStart();

		UGarbageTruck_BackDropEffectEventHandler::Trigger_StopForGarbage(this);

		OnStoppedForGarbage.Broadcast();

		BP_StopForGarbage();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StopForGarbage() {}

	UFUNCTION()
	private void UpdateStopForGarbage(float CurValue)
	{
		float ThrusterRot = Math::Lerp(-90.0, 0.0, CurValue);
		BackLeftThrusterRoot.SetRelativeRotation(FRotator(ThrusterRot, 0.0, 0.0));
		BackRightThrusterRoot.SetRelativeRotation(FRotator(ThrusterRot, 0.0, 0.0));
		FrontLeftThrusterRoot.SetRelativeRotation(FRotator(ThrusterRot, 0.0, 0.0));
		FrontRightThrusterRoot.SetRelativeRotation(FRotator(ThrusterRot, 0.0, 0.0));

		if (!StopForGarbageTimeLike.IsReversed())
		{
			FVector Loc = Math::Lerp(SplinePos.CurrentSpline.GetWorldLocationAtSplineFraction(StopForGarbageFraction - 0.05), SplinePos.CurrentSpline.GetWorldLocationAtSplineFraction(StopForGarbageFraction), CurValue);
			FRotator Rot = Math::LerpShortestPath(SplinePos.CurrentSpline.GetWorldRotationAtSplineFraction(StopForGarbageFraction - 0.05).Rotator(), SplinePos.CurrentSpline.GetWorldRotationAtSplineFraction(StopForGarbageFraction).Rotator(), CurValue);
			SetActorLocationAndRotation(Loc, Rot);
		}
	}

	UFUNCTION()
	private void FinishStopForGarbage()
	{
		
	}

	UFUNCTION()
	void ResumeAfterGarbageStop()
	{
		SplinePos = FSplinePosition(SplineActor.Spline, StopForGarbageFraction * SplineActor.Spline.SplineLength, true);

		MoveSpeed = 0.0;
		StartMoving();

		StopForGarbageTimeLike.ReverseFromEnd();

		bStoppedForGarbage = false;

		UGarbageTruck_BackDropEffectEventHandler::Trigger_ResumeAfterGarbageStop(this);

		BP_ResumeAfterGarbageStop();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ResumeAfterGarbageStop() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{ 
		if (bMoving)
		{
			if (!bStoppedForGarbage)
			{
				MoveSpeed = Math::FInterpConstantTo(MoveSpeed, 1250.0, DeltaTime, 500.0);
				SplinePos.Move(MoveSpeed * DeltaTime);
				SetActorLocationAndRotation(SplinePos.WorldLocation, SplinePos.WorldRotation);

				if (!SplinePos.CurrentSpline.IsClosedLoop() && SplinePos.CurrentSplineDistance >= SplinePos.CurrentSpline.SplineLength)
				{
					if (bResetOnEnd)
					{
						SplinePos = FSplinePosition(SplineActor.Spline, 0.0, true);
						TeleportActor(SplinePos.WorldLocation, SplinePos.WorldRotation.Rotator(), this);

						UGarbageTruck_BackDropEffectEventHandler::Trigger_Reset(this);
						bStoppedForGarbageThisCycle = false;
					}
					else
					{
						bReachedEnd = true;
						SetActorTickEnabled(false);
						OnReachedEndOfSpline.Broadcast();
					}
				}
			}

			float SplineFraction = SplinePos.CurrentSplineDistance/SplinePos.CurrentSpline.SplineLength;

			if (!bStoppedForGarbageThisCycle && SplineFraction >= StopForGarbageFraction - 0.05)
			{
				StopForGarbage();
			}
		}

		float HoverOffset = Math::Sin(Time::GameTimeSeconds * 1.5) * 8.0;

		float XOffset = Math::Sin(Time::GameTimeSeconds * 1.3) * 10.0;
		float YOffset = Math::Sin(Time::GameTimeSeconds * 2.2) * 5.0;
		TruckRoot.SetRelativeLocation(FVector(XOffset, YOffset, HoverOffset));
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void StartMoving()
	{
		bMoving = true;

		UGarbageTruck_BackDropEffectEventHandler::Trigger_StartMoving(this);
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void StopMoving()
	{
		bMoving = false;

		UGarbageTruck_BackDropEffectEventHandler::Trigger_StopMoving(this);
	}
}