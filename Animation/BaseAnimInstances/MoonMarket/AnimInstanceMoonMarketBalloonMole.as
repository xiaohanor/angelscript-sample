class UAnimInstanceMoonMarketBalloonMole : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData FloatingMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData StartFly;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Fall;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Crying;


	AMoonMarketMole Mole;

	UMoonMarketMoleHoldBalloonComponent BalloonComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasBalloon;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Mole = Cast<AMoonMarketMole>(HazeOwningActor);
		BalloonComp = UMoonMarketMoleHoldBalloonComponent::Get(Mole);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Mole == nullptr || BalloonComp == nullptr)
			return;

		bHasBalloon = BalloonComp.Balloon != nullptr;
	}
}