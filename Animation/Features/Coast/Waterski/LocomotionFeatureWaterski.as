struct FLocomotionFeatureWaterskiAnimData
{
	UPROPERTY(Category = "Waterski")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "Waterski")
	FHazePlayBlendSpaceData EnterNoHands;
	
	UPROPERTY(Category = "Waterski")
	FHazePlayBlendSpaceData MhNoHands;

	UPROPERTY(Category = "Waterski")
	FHazePlayBlendSpaceData ArmsOverride;

}

class ULocomotionFeatureWaterski : UHazeLocomotionFeatureBase
{
	default Tag = n"Waterski";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWaterskiAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
