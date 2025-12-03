namespace SanctuaryWeeperTags
{
	const FName Attack = n"Attack";
	const FName Freeze = n"Freeze";
	const FName DeathFire = n"DeathFire";
	const FName DeathSpike = n"DeathSpike";
	const FName DeathSquish = n"DeathSquish";
}	

class UAnimInstanceWeeperSpider : UAnimInstanceAIBase
{
    
    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Locomotion;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Attack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData OverrideFreeze;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayRndSequenceData DeathFire;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayRndSequenceData DeathSpike;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DeathSquish;

	// Custom Variables

	UPROPERTY()
	bool bDeathFire;

	UPROPERTY()
	bool bDeathSpike;

	UPROPERTY()
	bool bDeathSquish;

	UPROPERTY()
	bool bIsAttacking;

	UPROPERTY()
	bool bFreeze;

	UPROPERTY()
	float RndDeathRate;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		bDeathFire = false;
		bDeathSpike = false;
		bDeathSquish = false;

		RndDeathRate = Math::RandRange(1.2, 1.5);
   
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		bIsAttacking = IsCurrentFeatureTag(SanctuaryWeeperTags::Attack);
		bFreeze = IsCurrentFeatureTag(SanctuaryWeeperTags::Freeze);

		bDeathFire = IsCurrentFeatureTag(SanctuaryWeeperTags::DeathFire);
		bDeathSpike = IsCurrentFeatureTag(SanctuaryWeeperTags::DeathSpike);
		bDeathSquish = IsCurrentFeatureTag(SanctuaryWeeperTags::DeathSquish);
		
		#if EDITOR	

		/*
		*/
		#endif

		
	}

	UFUNCTION()
    void AnimNotify_SetDeathRate()
    {
        RndDeathRate = Math::RandRange(1.2, 1.5);
    }

    
}