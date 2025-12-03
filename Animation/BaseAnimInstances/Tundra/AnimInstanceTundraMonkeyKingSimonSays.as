enum EMonkeyKingSimonSaysBongoState
{
	Mh,
	Hit1,
	Hit2,
	Hit3,
	Hit4,
}

class UAnimInstanceTundraMonkeyKingSimonSays : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData BongoMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData BongoHit1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData BongoHit2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData BongoHit3;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData BongoHit4;

	UPROPERTY()
	EMonkeyKingSimonSaysBongoState BongoState;

	ATundra_SimonSaysMonkeyKing MonkeyKing;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor == nullptr)
			return;

		MonkeyKing = Cast<ATundra_SimonSaysMonkeyKing>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
			return;

		// if(MonkeyKing.AnimData.bIsMonkeyKingTurn)
		// {
		// 	BongoState = EMonkeyKingSimonSaysBongoState(MonkeyKing.AnimData.CurrentBeatIndex);
		// }
		// else
		// {
		// 	BongoState = EMonkeyKingSimonSaysBongoState::Mh;
		// }
	}
}