
namespace CoastPoltroonFeatureTag
{
	const FName Kneel = n"Kneel";
	const FName Attack = n"Attack";
	const FName Death = n"Death";
}

struct FCoastPoltroonFeatureTags
{
	UPROPERTY()
	FName Kneel = CoastPoltroonFeatureTag::Kneel;
	UPROPERTY()
	FName Attack = CoastPoltroonFeatureTag::Attack;
	UPROPERTY()
	FName Death = CoastPoltroonFeatureTag::Death;
}

class UAnimInstanceCoastPoltroon : UAnimInstanceAIBase
{
	// Animations 
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Kneel;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attack")
    FHazePlaySequenceData Attack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
    FHazePlaySequenceData Death;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FCoastPoltroonFeatureTags FeatureTags;

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);
	}
}