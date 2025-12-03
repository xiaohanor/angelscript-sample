namespace FeatureTagCrystalCrawler
{
	const FName Locomotion = n"Locomotion";
	const FName Attacks = n"Attacks";
	
}

struct FSummitCrystalCrawlerFeatureTags
{
	UPROPERTY()
	FName Locomotion = FeatureTagCrystalCrawler::Locomotion;
	
	UPROPERTY()
	FName Attacks = FeatureTagCrystalCrawler::Attacks;
	
	
}

namespace SummitCrystalCrawlerSubTags
{
	const FName AttackEnter = n"AttackEnter";

	const FName AttackMh = n"AttackMh";

	const FName AttackExit = n"AttackExit";

	const FName VulnerableEnter = n"VulnerableEnter";

	const FName VulnerableExit = n"VulnerableExit";

	const FName CombatRevealMh = n"CombatRevealMh";

	const FName CombatRevealEnter = n"CombatRevealEnter";

	const FName HitReaction = n"HitReaction";
	
}

struct FSummitCrystalCrawlerSubTags
{
	UPROPERTY()
	FName AttackEnter = SummitCrystalCrawlerSubTags::AttackEnter;

	UPROPERTY()
	FName AttackMh = SummitCrystalCrawlerSubTags::AttackMh;

	UPROPERTY()
	FName AttackExit = SummitCrystalCrawlerSubTags::AttackExit;

	UPROPERTY()
	FName VulnerableEnter = SummitCrystalCrawlerSubTags::VulnerableEnter;

	UPROPERTY()
	FName VulnerableExit = SummitCrystalCrawlerSubTags::VulnerableExit;

	UPROPERTY()
	FName CombatRevealMh = SummitCrystalCrawlerSubTags::CombatRevealMh;

	UPROPERTY()
	FName CombatRevealEnter = SummitCrystalCrawlerSubTags::CombatRevealEnter;


	UPROPERTY()
	FName HitReaction = SummitCrystalCrawlerSubTags::HitReaction;
	
}




class UAnimInstanceSummitCrystalCrawler : UAnimInstanceAIBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
	FHazePlaySequenceData CombatRevealMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
	FHazePlaySequenceData CombatRevealEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Attacks")
    FHazePlayRndSequenceData Attacks;


	

	// FeatureTags and SubTags

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSummitCrystalCrawlerFeatureTags FeatureTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSummitCrystalCrawlerSubTags SubTags;

	

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        Super::BlueprintInitializeAnimation();
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        Super::BlueprintUpdateAnimation(DeltaTime);
    }
}