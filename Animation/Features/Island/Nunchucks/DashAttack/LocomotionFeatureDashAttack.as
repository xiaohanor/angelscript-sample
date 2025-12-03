struct FLocomotionFeatureDashAttackAnimData
{
	UPROPERTY(Category = "DashAttack")
	FHazePlaySequenceData DashAttack;
}

class ULocomotionFeatureDashAttack : UHazeLocomotionFeatureBase
{
	default Tag = n"DashAttack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDashAttackAnimData AnimData;
}
