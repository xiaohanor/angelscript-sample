struct FLocomotionFeatureNunchuckAOEAttackAnimData
{
	UPROPERTY(Category = "NunchuckAOEAttack")
	FHazePlaySequenceData NunchuckIdleMH;
	
	
	UPROPERTY(Category = "NunchuckAOEAttack")
	FHazePlaySequenceData NunchuckAOEAttackStart;

	UPROPERTY(Category = "NunchuckAOEAttack")
	FHazePlaySequenceData NunchuckAOEAttack;
}

class ULocomotionFeatureNunchuckAOEAttack : UHazeLocomotionFeatureBase
{
	default Tag = n"NunchuckAOEAttack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureNunchuckAOEAttackAnimData AnimData;
}
