class UAnimInstanceSketchBookGoat : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Run;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData PerchJump1;
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData PerchJump2;
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData PerchJump3;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int PerchPointIndex;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInAir;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LenghtModifier;

	AHazePlayerCharacter Player;

	ASketchbookGoat Goat;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Goat = Cast<ASketchbookGoat>(HazeOwningActor);
		if (Goat == nullptr)
			return;

		PerchPointIndex = 0;

		LenghtModifier = FVector(0, 0, Goat.LenghtModifier / 3.0);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Goat == nullptr)
			return;

		bIsMoving = Goat.MoveComp.GetVelocity().Size() > 150 && Goat.IsMounted();
		bIsInAir = Goat.IsInAir();

		if(GetAnimBoolParam(n"LandedOnPerch"))
			bIsInAir = false;

		bJump = GetAnimTrigger(n"Jump");
		if (bJump)
		{
			PerchPointIndex = GetAnimIntParam(n"PerchPointIndex", true, 0);
			PerchPointIndex = Math::WrapIndex(PerchPointIndex, 0, 4); // We only have 3 animations
		}
	}
}