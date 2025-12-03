struct FLocomotionFeatureSandHandAnimData
{
	UPROPERTY(Category = "SandHand")
	FHazePlaySequenceData ThrowLeft;

	UPROPERTY(Category = "SandHand")
	FHazePlaySequenceData ThrowRight;
	
}

class ULocomotionFeatureSandHand : UHazeLocomotionFeatureBase
{
	default Tag = SandHand::Feature;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSandHandAnimData AnimData;
}
