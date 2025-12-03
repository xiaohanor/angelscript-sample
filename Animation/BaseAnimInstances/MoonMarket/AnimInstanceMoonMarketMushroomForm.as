class UAnimInstanceMoonMarketMushroomForm : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Stop;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayerControlled;

	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter Player;

	bool bFirstTick = true;

	void Initialize()
	{
		Player = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachmentRootActor);
		if (Player != nullptr)
			MoveComp = UHazeMovementComponent::Get(Player);
		else
			MoveComp = UHazeMovementComponent::Get(HazeOwningActor);

		bIsPlayerControlled = Player != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;


		if (MoveComp == nullptr)
		{
			if(bFirstTick)
			{
				bFirstTick = false;
				return;
			}

			Initialize();
			return;
		}

		Speed = MoveComp.Velocity.SizeSquared() / 450;
		if (Player != nullptr)
			bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		else
			bWantsToMove = Speed > 5;
	}
}
