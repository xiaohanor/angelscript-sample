struct FLocomotionFeatureDragonSwordCombatStandardAttackAnimData
{
	UPROPERTY(Category = "StandardAttack")
	FHazePlaySequenceData Attack1;

	UPROPERTY(Category = "StandardAttack")
	FHazePlaySequenceData Attack1Settle;

	UPROPERTY(Category = "StandardAttack")
	FHazePlaySequenceData Attack2;

	UPROPERTY(Category = "StandardAttack")
	FHazePlaySequenceData Attack2Settle;

	UPROPERTY(Category = "StandardAttack")
	FHazePlaySequenceData Attack3;

	UPROPERTY(Category = "StandardAttack")
	FHazePlaySequenceData Attack3Settle;

	UPROPERTY(Category = "DashAttack")
	FHazePlaySequenceData DashAttack1;

	UPROPERTY(Category = "DashAttack")
	FHazePlaySequenceData DashAttack1Settle;

	UPROPERTY(Category = "SlideAttack")
	FHazePlaySequenceData SlideAttack1;

	UPROPERTY(Category = "SlideAttack")
	FHazePlaySequenceData SlideAttack1Settle;

}

class ULocomotionFeatureDragonSwordCombatStandardAttack : UHazeLocomotionFeatureBase
{
	default Tag = n"StandardAttack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDragonSwordCombatStandardAttackAnimData AnimData;
}
