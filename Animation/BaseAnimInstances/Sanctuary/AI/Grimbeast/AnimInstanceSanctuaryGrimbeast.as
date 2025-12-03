namespace SanctuaryGrimbeastFeatureTag
{
	const FName Locomotion = n"Locomotion";
	const FName Melee = n"Melee";
	const FName Mortar = n"Mortar";
	const FName Boulder = n"Boulder";
}

struct FSanctuaryGrimbeastFeatureTags
{
	UPROPERTY()
	FName Locomotion = SanctuaryGrimbeastFeatureTag::Locomotion;
	UPROPERTY()
	FName Melee = SanctuaryGrimbeastFeatureTag::Melee;
	UPROPERTY()
	FName Mortar = SanctuaryGrimbeastFeatureTag::Mortar;
	UPROPERTY()
	FName Boulder = SanctuaryGrimbeastFeatureTag::Boulder;
}

class UAnimInstanceSanctuaryGrimbeast : UAnimInstanceAIBase
{
	// Animations 

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attack")
    FHazePlaySequenceData Melee;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attack")
    FHazePlaySequenceData Mortar;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attack")
    FHazePlaySequenceData Boulder;

	// FeatureTags and SubTags

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSanctuaryGrimbeastFeatureTags FeatureTags;

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);
	}
}