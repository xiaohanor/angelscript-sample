struct FLocomotionFeatureWalkingStickRiseAnimData
{
	UPROPERTY(Category = "WalkingStickRise")
	FHazePlaySequenceData WalkingStickRise;

	UPROPERTY(Category = "WalkingStickRise")
	FHazePlaySequenceData WalkingWalk;
	
	
}

class ULocomotionFeatureWalkingStickRise : UHazeLocomotionFeatureBase
{
	default Tag = n"WalkingStickRise";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWalkingStickRiseAnimData AnimData;
}
