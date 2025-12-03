struct FTundraBirdEggAnimData
{
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

	
}

class UAnimInstanceTundraBirdEgg : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Generic")
	FHazePlaySequenceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Generic")
	FHazePlaySequenceData RotToPlayer;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Generic")
	FHazePlaySequenceData Primed;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Generic")
	FHazePlaySequenceData Launch;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Generic")
	FHazePlaySequenceData Hoover;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Generic")
	FHazePlaySequenceData Hit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Generic")
	FHazePlaySequenceData Panic;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Generic")
	FHazePlaySequenceData JumpAway;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Generic")
	FHazePlaySequenceData RunAway;

	UPROPERTY(EditDefaultsOnly, BlueprintHidden, Category = "Animations")
	FTundraBirdEggAnimData AnimDataSnowMonkey;

	UPROPERTY(EditDefaultsOnly, BlueprintHidden, Category = "Animations")
	FTundraBirdEggAnimData AnimDataTreeGuardian;

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

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsCarriedBySnowMonkey;

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

		bIsCarriedBySnowMonkey = CrackBird.InteractingPlayer == Game::Mio;

		bPickedUp = bAttached || CrackBird.IsPickedUp();
		bIsPuttingDownBird = CrackBird.GetState() == ETundraCrackBirdState::PuttingDown;

		if (bPickedUp)
		{
			if (MoveComp != nullptr)
				bIsMoving = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		}
		else
		{
			bIsLaunched = CrackBird.bIsLaunched;
			bIsRotating = CrackBird.bIsRotating;
			bIsPrimed = CrackBird.bIsPrimed;
			bIsHit = CrackBird.bIsHit;
			bCurrentlyHovering = CrackBird.bIsHovering;
		}
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	FTundraBirdEggAnimData GetPlayerSpesificAnimData()
	{
		if (bIsCarriedBySnowMonkey)
			return AnimDataSnowMonkey;

		return AnimDataTreeGuardian;
	}
}