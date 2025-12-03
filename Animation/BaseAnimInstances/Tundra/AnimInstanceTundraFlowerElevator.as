class UAnimInstanceTundraFlowerElevator : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData IdleDead;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Land;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Smash;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Rise;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RiseOpen;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RiseMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData LiveDead;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData SmashOpen;

	// Custom Variables
	UPROPERTY()
	bool bIsLanding;

	UPROPERTY()
	bool bIsSmashing;

	UPROPERTY()
	bool bIsRising;

	UPROPERTY()
	float HeightAlpha;

	ATundraRiver_GrowingFlower GrowingFlower;
	ATundraRiver_SplineGrowingFlower SplineGrowingFlower;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(HazeOwningActor == nullptr)
			return;

		GrowingFlower = Cast<ATundraRiver_GrowingFlower>(HazeOwningActor);
		SplineGrowingFlower = Cast<ATundraRiver_SplineGrowingFlower>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (GrowingFlower == nullptr && SplineGrowingFlower == nullptr)
			return;

		FTundraRiver_GrowingFlowerAnimData AnimData;
		if(GrowingFlower != nullptr)
			AnimData = GrowingFlower.AnimData;
		else
			AnimData = SplineGrowingFlower.AnimData;

		bIsLanding = AnimData.LandedThisFrame();
		bIsSmashing = AnimData.SmashedThisFrame();
		bIsRising = AnimData.bTreeGuardianInteracting;
		HeightAlpha = AnimData.HeightAlpha;
	}
}