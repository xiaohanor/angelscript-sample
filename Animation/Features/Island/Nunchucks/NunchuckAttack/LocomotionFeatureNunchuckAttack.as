struct FLocomotionFeatureNunchuckAttackAnimData
{
	UPROPERTY(Category = "NunchuckAttack")
	FHazePlaySequenceData Attack;

	UPROPERTY(Category = "NunchuckAttack")
	FHazePlaySequenceData Settle;
}

class ULocomotionFeatureNunchuckAttack : UHazeLocomotionFeatureBase
{
	default Tag = n"NunchuckAttack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureNunchuckAttackAnimData AnimData;
}
