class AClimbableMovingPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	TArray<FVector> PointLocations;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailReponseComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailClimbableComponent ClimbComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bBackAndForth;
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bAutomaticMovement = true;
	UPROPERTY(EditAnywhere, Category = "Settings")
	int SpinDirection = 1;
	UPROPERTY(EditAnywhere, Category = "Settings")
	float SpinSpeed = 15.0;

	int Index = 0;
	bool bMovingForward = true;
	bool bWaitToMove;
	FVector TargetLocation;
	FVector StartLocation;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 200.0;
	UPROPERTY(EditAnywhere)
	float StillDuration = 1.5;
	float StillDurationTimer;

	bool bMakeCustomMove;
	int MakeCustomMoveAmount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PointLocations.Num() > 0)
			MeshRoot.RelativeLocation = PointLocations[Index];
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, TargetLocation, DeltaSeconds, MoveSpeed);
		MeshRoot.AddLocalRotation(FRotator(0.0, SpinSpeed * DeltaSeconds, 0.0));

		if(!bWaitToMove)
		{
			if(GetDistanceToTargetLocation() < 0.01)
			{
				bWaitToMove = true;

				if(bAutomaticMovement)
					OnReachTargetLocation();
				else if (bMakeCustomMove && MakeCustomMoveAmount > 0)
					OnReachTargetLocation();
			}
		}
		else if(bWaitToMove && bAutomaticMovement)
		{
			if(StillDurationTimer <= Time::GetGameTimeSeconds())
			{
				SetNextLocation();
			}
		}
	}

	float GetDistanceToTargetLocation()
	{
		return (MeshRoot.RelativeLocation - TargetLocation).Size();
	}

	void SetNextLocation()
	{
		bWaitToMove = false;

		if(bBackAndForth)
		{
			if(bMovingForward)
				Index++;
			else
				Index--;

			if(Index == 0 || Index == PointLocations.Num() - 1)
				bMovingForward = !bMovingForward;
		}
		else
		{
			if(Index == PointLocations.Num() - 1)
				Index = 0;
			else
				Index++;
		}

		// TODO proper fix
		if(PointLocations.Num() <= Index)
			return;
		
		TargetLocation = PointLocations[Index];

		if (MakeCustomMoveAmount > 0)
			MakeCustomMoveAmount--;
		else if (bMakeCustomMove)
			bMakeCustomMove = false;
	}

	UFUNCTION()
	private void OnReachTargetLocation()
	{
		StillDurationTimer = Time::GetGameTimeSeconds() + StillDuration;
	}

	UFUNCTION()
	void ActivateAutoMovement()
	{
		bAutomaticMovement = true;
	}

	UFUNCTION()
	void MakeMove(int MoveAmounts)
	{
		MakeCustomMoveAmount = MoveAmounts;
		bMakeCustomMove = true;
		SetNextLocation();
	}
}