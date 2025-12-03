class AWheelTranslateActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditAnywhere)
	ASummitRollingWheel RollingWheel;

	UPROPERTY(EditAnywhere)
	bool bCanReturnToStart;

	UPROPERTY(EditAnywhere)
	float WheelForce = 16900.0;
	
	UPROPERTY(EditAnywhere)
	float ClampMoveAmount = 2500.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bGoTowardsOriginalPosition", EditConditionHides))
	float ReturnForce = 8800.0;

	UPROPERTY(EditAnywhere)
	bool bInvertDirection = false;

	UPROPERTY(EditAnywhere)
	bool bXAxis = true;
	UPROPERTY(EditAnywhere)
	bool bYAxis = true;
	UPROPERTY(EditAnywhere)
	bool bZAxis = true;

	UPROPERTY(EditAnywhere)
	bool bDebug;

	FVector StartLocation;
	FVector MoveDirection;
	FHazeAcceleratedVector AccelVector;
	FVector TargetLocation;
	
	float MoveValue;
	float TargetMoveValue;

	bool bReturningToStart;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		TargetLocation = ActorLocation;

		RollingWheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolled");

		if (bXAxis)
		{
			MoveDirection += ActorForwardVector;
		}

		if (bYAxis)
		{
			MoveDirection += ActorRightVector;
		}

		if (bZAxis)
		{
			MoveDirection += ActorUpVector;
		}

		MoveDirection.Normalize();

		if (bInvertDirection)
			MoveDirection = -MoveDirection;

		AccelVector.SnapTo(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TargetMoveValue == 0.0)
			bReturningToStart = true;
		else
			bReturningToStart = false;

		if (TargetMoveValue == 0.0)
		{
			if (bCanReturnToStart && bReturningToStart)
				TargetLocation = Math::VInterpConstantTo(ActorLocation, StartLocation, DeltaTime, ReturnForce);
		}
		else
		{
			FVector ToLoc;

			if (TargetMoveValue > 0.0)
				ToLoc = StartLocation + (MoveDirection * ClampMoveAmount);
			else
				ToLoc = StartLocation + (-MoveDirection * ClampMoveAmount);

			TargetLocation = Math::VInterpConstantTo(ActorLocation, ToLoc, DeltaTime, WheelForce);
		}

		AccelVector.AccelerateTo(TargetLocation, 1.1, DeltaTime);
		ActorLocation = AccelVector.Value;
		TargetMoveValue = 0.0;
	}

	UFUNCTION()
	private void OnWheelRolled(float Amount)
	{
		if (Amount > 0.0)
			TargetMoveValue = WheelForce;
		else if (Amount < 0.0)
			TargetMoveValue = -WheelForce;
	}
}