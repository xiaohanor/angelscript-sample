
struct FLocomotionFeatureAIMeleeCombatData
{
    UPROPERTY(BlueprintReadOnly, Category = "AIMeleeCombat")
    FHazePlaySequenceData MediumAttack1;

	UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData MediumAttack2;

	UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData MediumAttack3;

	UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData Charge1_Start;

	UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData Charge1_MH;

	UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData Charge1_End;

	UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData HeavyAttack1;

	UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData IdleMH;

    UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData MediumAttack1Anticipation;

    UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData MediumAttack2Anticipation;

    UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData MediumAttack3Anticipation;

    UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData MediumAttack1Settle;

    UPROPERTY(Category = "AIMeleeCombat")
    FHazePlaySequenceData MediumAttack2Settle;

}

class ULocomotionFeatureAIMeleeCombat : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::MeleeCombat;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIMeleeCombatData FeatureData;
}