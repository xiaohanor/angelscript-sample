class UAnimInstanceMoonMarketFrog : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Land;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInAir;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UWitchPlayerMushroomBounceComponent BounceComp;

	void Initialize()
	{
		Player = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
		MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);

		if (Player != nullptr)
			BounceComp = UWitchPlayerMushroomBounceComponent::GetOrCreate(Player);
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

		bJump = GetAnimTrigger(n"Bounce");

		if(Player != nullptr)
			bInAir = MoveComp.IsInAir() && !BounceComp.HasBouncedThisFrame();
		else
			bInAir = GetAnimBoolParam(n"InAir");
	}
}