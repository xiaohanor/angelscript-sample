class UAnimInstanceMoonMarketChicken : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData AirMovement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Land;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInAir;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	void Initialize()
	{
		Player = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
		MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (MoveComp == nullptr)
		{
			if (HazeOwningActor != nullptr && HazeOwningActor.AttachParentActor != nullptr)
				Initialize();

			return;
		}

		Speed = HazeOwningActor.AttachParentActor.ActorVelocity.SizeSquared() / 450;

		if(Player != nullptr)
		{
			bIsMoving = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
			bInAir = MoveComp.IsInAir();
		}
		else
		{
			bIsMoving = Speed > 0;
			bInAir = GetAnimBoolParam(n"InAir");
		}
	}
}