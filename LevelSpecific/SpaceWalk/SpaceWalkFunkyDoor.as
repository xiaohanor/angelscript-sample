class ASpaceWalkFunkyDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeftDoor;
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeftDoorTarget;
	default LeftDoorTarget.SetHiddenInGame(true);
	default LeftDoorTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RightDoor;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RightDoorTarget;
	default RightDoorTarget.SetHiddenInGame(true);
	default RightDoorTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DoorFrame;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DoorOpening;
	default DoorOpening.Duration = 2;
	default DoorOpening.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	float StartDelay;

	FVector LeftStart;
	FVector LeftTarget;
	FVector RightStart;
	FVector RightTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftStart = LeftDoor.RelativeLocation;
		LeftTarget = LeftDoorTarget.RelativeLocation;

		RightStart = RightDoor.RelativeLocation;
		RightTarget = RightDoorTarget.RelativeLocation;

		DoorOpening.BindFinished(this, n"OnFinished");
		DoorOpening.BindUpdate(this, n"DoorUpdate");
	}

	UFUNCTION(BlueprintCallable)
	void InitializeDoor()
	{
		Timer::SetTimer(this, n"StartDoor",StartDelay);
	}

	UFUNCTION()
	private void StartDoor()
	{
		DoorOpening.PlayFromStart();
	}

	UFUNCTION()
	private void DoorUpdate(float CurrentValue)
	{
		LeftDoor.SetRelativeLocation(Math::Lerp(LeftStart, LeftTarget, CurrentValue));

		RightDoor.SetRelativeLocation(Math::Lerp(RightStart, RightTarget, CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
		if(DoorOpening.IsReversed())
		{
			DoorOpening.PlayFromStart();
			return;
		}

		DoorOpening.ReverseFromEnd();

	}
};