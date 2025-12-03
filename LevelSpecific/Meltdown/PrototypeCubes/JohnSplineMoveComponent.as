class UJohnSplineMoveComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	bool bStartActive = true;

	UPROPERTY(EditAnywhere)
	float Speed = 200.0;

	UPROPERTY(EditAnywhere)
	bool bFollowRotation = false;

	UPROPERTY(EditAnywhere)
	float InterpSpeed = 400.0;

	UPROPERTY(EditAnywhere)
	bool bBackAndForth = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bBackAndForth", EditConditionHides))
	float PauseDuration = 0.0;
	float PauseTime;

	float TargetSpeed;
	float CurrentSpeed;
	bool bIsActive;

	UHazeSplineComponent SplineComp;
	FSplinePosition SplinePos;

	int Direction = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = SplineActor.Spline;
		SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
	
		bIsActive = bStartActive;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsActive)
		{
			if (Time::GameTimeSeconds > PauseTime)
				TargetSpeed = Speed;
		}
		else
		{
			TargetSpeed = 0.0;
		}

		CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaSeconds, InterpSpeed);

		if (bBackAndForth && !SplineComp.IsClosedLoop())
		{
			if (SplinePos.CurrentSplineDistance >= SplineComp.SplineLength && Direction > 0)
			{
				Direction = -1;
				RunPause();
			}
			else if (SplinePos.CurrentSplineDistance == 0.0 && Direction < 0)
			{
				Direction = 1;
				RunPause();
			}
		}
		
		SplinePos.Move(CurrentSpeed * Direction * DeltaSeconds);
		Owner.ActorLocation = SplinePos.WorldLocation;
		if (bFollowRotation)
			Owner.ActorRotation = SplinePos.WorldRotation.Rotator();
	}

	void RunPause()
	{
		if (PauseDuration > 0.0 && bBackAndForth)
		{
			CurrentSpeed = 0.0;
			PauseTime = Time::GameTimeSeconds + PauseDuration;
		}
	}
}