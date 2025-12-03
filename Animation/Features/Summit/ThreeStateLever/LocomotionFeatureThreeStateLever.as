struct FLocomotionFeatureThreeStateLeverAnimData
{
	UPROPERTY(Category = "ThreeStateLever")
	FHazePlaySequenceData EnterLeft;

	UPROPERTY(Category = "ThreeStateLever")
	FHazePlaySequenceData EnterRight;

	UPROPERTY(Category = "ThreeStateLever")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "ThreeStateLever")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureThreeStateLever : UHazeLocomotionFeatureBase
{
	default Tag = n"ThreeStateLever";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureThreeStateLeverAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
