struct FLocomotionFeatureAIRollDodgeAnimData
{
	UPROPERTY(Category = "RollDodge")
	FHazePlaySequenceData RollDodgeLeft;

	UPROPERTY(Category = "RollDodge")
	FHazePlaySequenceData RollDodgeRight;
}

class ULocomotionFeatureAIRollDodge : UHazeLocomotionFeatureBase
{
	default Tag = n"RollDodge";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAIRollDodgeAnimData AnimData;
}
