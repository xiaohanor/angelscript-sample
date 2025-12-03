class UAnimInstanceAlienCruiser : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData AirMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ToGround;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Grounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SpinnerRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bToGround;

	AAlienCruiser AlienCruiser;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		AlienCruiser = Cast<AAlienCruiser>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (AlienCruiser == nullptr)
			return;

		SpinnerRotation.Roll += DeltaTime * AlienCruiser.CurrentRotationSpeed;
		bToGround = AlienCruiser.MoveDownAlpha > 0;
	}
}