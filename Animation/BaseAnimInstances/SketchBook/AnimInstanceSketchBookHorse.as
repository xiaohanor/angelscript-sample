class UAnimInstanceSketchBookHorse : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Trot;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Landing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGrounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	AHazePlayerCharacter OwningPlayer;
	UPlayerMovementComponent MovementComponent;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Setup();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		Setup();
	}

	void Setup()
	{
		if (HazeOwningActor == nullptr)
			return;
		
		OwningPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
		if (OwningPlayer == nullptr)
			return;

		MovementComponent = UPlayerMovementComponent::Get(OwningPlayer);
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (OwningPlayer == nullptr)
		{
			Setup();
			return;
		}

		bJump = GetAnimTrigger(n"Jump");
		bGrounded = MovementComponent.HasGroundContact();
		bIsMoving = !MovementComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, .3);
		if (OwningPlayer.ActorForwardVector.Y < 0)
			SlopeRotation *= -1;

		// The actor itself isn't rotating, so we need to do this check to correct the slope rotation
		if (OwningComponent.GetForwardVector().Y > 0)
			SlopeRotation *= -1;
	}
}