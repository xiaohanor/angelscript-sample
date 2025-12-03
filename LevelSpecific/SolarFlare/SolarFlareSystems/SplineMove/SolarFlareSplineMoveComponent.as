event void FOnSolarFlareSplineMoveCompReachedEnd();
event void FOnSolarFlareSplineMoveCompReachedStart();
event void FOnSolarFlareSplineMoveCompStopMoving();
event void FOnSolarFlareSplineMoveCompStartMoving();

class USolarFlareSplineMoveComponent : UHazeCapabilityComponent
{
	default DefaultCapabilities.Add(n"SolarFlareSplineMoveCapability");

	UPROPERTY()
	FOnSolarFlareSplineMoveCompReachedStart OnSolarFlareSplineMoveCompReachedStart;

	UPROPERTY()
	FOnSolarFlareSplineMoveCompReachedEnd OnSolarFlareSplineMoveCompReachedEnd;

	UPROPERTY()
	FOnSolarFlareSplineMoveCompStopMoving OnSolarFlareSplineMoveCompStopMoving;
	
	UPROPERTY()
	FOnSolarFlareSplineMoveCompStartMoving OnSolarFlareSplineMoveCompStartMoving;

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

	UPROPERTY(EditAnywhere)
	int StartingDirection = 1;

	UPROPERTY(EditAnywhere)
	float DirectionInterpSpeed = 2.5;

	UPROPERTY(EditAnywhere)
	bool bDebugPrint;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bBackAndForth", EditConditionHides))
	float PauseDuration = 0.0;
	float PauseTime;

	float TargetSpeed;
	float CurrentSpeed;
	bool bIsActive;

	UHazeSplineComponent SplineComp;
	FSplinePosition SplinePos;

	float Direction = 1;
	float DirectionTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Direction = StartingDirection;
		DirectionTarget = StartingDirection;
		
		SplineComp = SplineActor.Spline;
		SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
	
		bIsActive = bStartActive;
	}

	void SetInitialLocation()
	{
		SplineComp = SplineActor.Spline;
		SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
		Owner.ActorLocation = SplinePos.WorldLocation;
	}

	void ActivateSplineMovement()
	{
		bIsActive = true;
	}

	void RunPause()
	{
		if (bDebugPrint)
			Print("RunPause");

		if (PauseDuration > 0.0 && bBackAndForth)
		{
			CurrentSpeed = 0.0;
			PauseTime = Time::GameTimeSeconds + PauseDuration;

			if (bDebugPrint)
				Print("PauseTime: " + PauseTime);
		}
	}

	void ChangeDirection(int NewDirection)
	{
		Direction = 0.0;
		DirectionTarget = NewDirection;
	}

	void ChangeDirectionInterpSpeed(float NewSpeed)
	{
		DirectionInterpSpeed = NewSpeed;
	}

	void SetToEndLocation()
	{
		SplinePos.Move(SplineComp.SplineLength);
		Owner.SetActorLocation(SplinePos.WorldLocation);
	}
}