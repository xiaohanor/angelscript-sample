struct FLocomotionFeatureWaterskiJumpAnimData
{
	UPROPERTY(Category = "WaterskiTricks")
	FHazePlayRndSequenceData Tricks;
	
	UPROPERTY(Category = "WaterskiJump")
	FHazePlayBlendSpaceData JumpCharge;

	UPROPERTY(Category = "WaterskiJump")
	FHazePlayBlendSpaceData JumpMh;

	UPROPERTY(Category = "WaterskiJump")
	FHazePlayBlendSpaceData JumpExit;
}

class ULocomotionFeatureWaterskiJump : UHazeLocomotionFeatureBase
{
	default Tag = n"WaterskiJump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWaterskiJumpAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
