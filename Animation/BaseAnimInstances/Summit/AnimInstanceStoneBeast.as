class UAnimInstanceSummitStoneBeast : UHazeAnimInstanceBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WaterFallMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HoverAttackEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HoverAttackMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HoverAttackExit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WaterfallHoverAttackEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WaterfallHoverAttackMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WaterfallHoverAttackExit;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData SpikeRoll;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RockGapEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RockGapMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RockGapExit;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	float UpwardsAlignment;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	float Banking;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	ESerpentAttackMovementState AttackState;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsInWaterfall;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsInRockGap;

	FQuat CachedActorRotation;

	ASerpentHead SerpentHead;
	USerpentMovementSettings MovementSettings;

	// FeatureTags and SubTags

	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		SerpentHead = Cast<ASerpentHead>(HazeOwningActor);
		MovementSettings = USerpentMovementSettings::GetSettings(SerpentHead);
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;


		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime, 20);
		UpwardsAlignment = CachedActorRotation.ForwardVector.DotProduct(FVector::UpVector);

		AttackState = SerpentHead.SerpentAttackMovementState;
		bIsInWaterfall = SerpentHead.bIsInWaterfall;
		bIsInRockGap = SerpentHead.bIsInRockGap;
	}
}