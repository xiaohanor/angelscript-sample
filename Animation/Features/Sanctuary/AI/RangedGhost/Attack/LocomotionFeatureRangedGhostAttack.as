struct FLocomotionFeatureRangedGhostAttackAnimData
{
	UPROPERTY(Category = "ThrowAttack")
	FHazePlaySequenceData Attack;
}

class ULocomotionFeatureRangedGhostAttack : UHazeLocomotionFeatureBase
{
	default Tag = n"RangedGhostAttack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRangedGhostAttackAnimData AnimData;
}
