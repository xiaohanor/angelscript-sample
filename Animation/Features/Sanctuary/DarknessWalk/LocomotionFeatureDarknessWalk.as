struct FLocomotionFeatureDarknessWalkAnimData
{
	UPROPERTY(Category = "DarknessWalk")
	FHazePlaySequenceData DefaultAnimation;
}

class ULocomotionFeatureDarknessWalk : UHazeLocomotionFeatureBase
{
	default Tag = n"DarknessWalk";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDarknessWalkAnimData AnimData;
}
