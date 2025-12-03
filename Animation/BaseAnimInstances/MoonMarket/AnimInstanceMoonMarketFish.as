class UAnimInstanceMoonMarketFish : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData Flop;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBounce;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		bBounce = GetAnimTrigger(n"Bounce");
	}
}