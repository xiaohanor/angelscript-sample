class UAnimInstanceMoonMarketFatMushroom : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData StartPush;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData PushedMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData StopPush;

	UPROPERTY(Transient, BlueprintReadOnly)
	bool bIsPushed;

	AMoonMarketGardenFatMushroom Mushroom;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Mushroom = Cast<AMoonMarketGardenFatMushroom>(HazeOwningActor);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(Mushroom == nullptr)
			return;

		bIsPushed = Mushroom.bIsPushed;
	}
}