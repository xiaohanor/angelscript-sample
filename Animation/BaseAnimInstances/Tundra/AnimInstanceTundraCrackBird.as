class UAnimInstanceTundraCrackBird : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RotToPlayer;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData PickUp;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData PickUpMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WalkStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Walk;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WalkStop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData PutDown;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Primed;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Launch;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Hoover;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Hit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Panic;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData JumpAway;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RunAway;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bPickedUp;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsMoving;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsRotating;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsPuttingDownBird;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsLaunched;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsPrimed;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bCurrentlyHovering;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsHit;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bEggPickedUp;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bHopOffCatapult;
	
	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bRunningAway;

	UBigCrackBirdCarryComponent BirdCarryComp;
	ABigCrackBird CrackBird;
	UHazeMovementComponent MoveComp;

	bool bAttached;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		CrackBird = Cast<ABigCrackBird>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (CrackBird == nullptr)
			return;

		if (CheckValueChangedAndSetBool(bAttached, CrackBird.IsPickedUp(), EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor.AttachParentActor);
			// These components are located on the player (parent of TreeGuardian)
			MoveComp = UHazeMovementComponent::Get(Player);
			BirdCarryComp = UBigCrackBirdCarryComponent::Get(Player);
		}

		bPickedUp = bAttached || CrackBird.IsPickedUp();
		bEggPickedUp = CrackBird.bEggPickedUp;
		
		if (bPickedUp)
		{
			if (MoveComp != nullptr)
				bIsMoving = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		}
		else
		{
			bIsPuttingDownBird = CrackBird.GetState() == ETundraCrackBirdState::PuttingDown;
			bRunningAway = CrackBird.bRunningAway;
			bHopOffCatapult = CrackBird.bHopOffCatapult;
			bIsLaunched = CrackBird.bIsLaunched;
			bIsRotating = CrackBird.bIsRotating;
			bIsPrimed = CrackBird.bIsPrimed;
			bIsHit = CrackBird.bIsHit;
			//bCurrentlyHovering = CrackBird.bCurrentlyHovering;
		}
	}
}