struct FLocomotionFeatureSwordWindWalkAnimData
{
	UPROPERTY(Category = "SwordWindWalk")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "SwordWindWalk")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "SwordWindWalk")
	FHazePlayBlendSpaceData Locomotion;
	
	UPROPERTY(Category = "SwordWindWalk")
	FHazePlaySequenceData Stop;


}

class ULocomotionFeatureSwordWindWalk : UHazeLocomotionFeatureBase
{
	default Tag = n"SwordWindWalk";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSwordWindWalkAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
