event void FOnFreakyReachedEndOfSpline();

class UMoonMarketFollowSplineComp : UActorComponent
{
	UPROPERTY()
	FOnFreakyReachedEndOfSpline OnFreakyReachedEndOfSpline;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;

	UPROPERTY(EditAnywhere)
	float Speed = 800.0;
	float CurrentSpeed = 0.0;

	UPROPERTY(EditAnywhere)
	bool bStartActive = true;

	UPROPERTY(EditInstanceOnly)
	float AccelVecDuration = 1.0;
	UPROPERTY(EditInstanceOnly)
	float AccelRotDuration = 2.0;

	float SpeedChangePerSecond = 200.0;

	FSplinePosition SplinePos;

	bool bReachedEnd;

	bool bFollowActive;

	FHazeAcceleratedVector AccelVec;
	FHazeAcceleratedRotator AccelRot;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(bStartActive);

		if (SplineActor == nullptr)
			return;

		Spline = SplineActor.Spline;
		float Dist = Spline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
		SplinePos = Spline.GetSplinePositionAtSplineDistance(Dist);
	
		AccelVec.SnapTo(Owner.ActorLocation);
		AccelRot.SnapTo(Owner.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SplineActor == nullptr)
			return;
		
		CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, Speed, DeltaSeconds, SpeedChangePerSecond);
		SplinePos.Move(CurrentSpeed * DeltaSeconds);

		AccelVec.AccelerateTo(SplinePos.WorldLocation, AccelVecDuration, DeltaSeconds);
		AccelRot.AccelerateTo(SplinePos.WorldRotation.Rotator(), AccelRotDuration, DeltaSeconds);
		Owner.ActorLocation = AccelVec.Value;
		Owner.ActorRotation = AccelRot.Value;

		if (!Spline.IsClosedLoop())
		{
			if (SplinePos.CurrentSplineDistance == Spline.SplineLength && !bReachedEnd)
			{
				OnFreakyReachedEndOfSpline.Broadcast();
				bReachedEnd = true;
			}
			else if (SplinePos.CurrentSplineDistance != Spline.SplineLength)
			{
				bReachedEnd = false;
			}
		}
	}

	void ActivateSplineFollow()
	{
		SetComponentTickEnabled(true);
		bFollowActive = true;
	}

	void DeactivateSplineFollow()
	{
		SetComponentTickEnabled(false);
		bFollowActive = false;
	}

	float GetFollowSplineAlphaProgress()
	{
		return Math::Saturate(SplinePos.CurrentSplineDistance / SplineActor.Spline.SplineLength);
	}
};