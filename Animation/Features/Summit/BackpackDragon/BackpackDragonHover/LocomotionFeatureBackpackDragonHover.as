struct FLocomotionFeatureBackpackDragonHoverAnimData
{
	UPROPERTY(Category = "BackpackDragonHover")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "BackpackDragonHover")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "BackpackDragonHover")
	FHazePlaySequenceData HoverDash;

	UPROPERTY(Category = "BackpackDragonHover")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureBackpackDragonHover : UHazeLocomotionFeatureBase
{
	default Tag = n"BackpackDragonHover";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBackpackDragonHoverAnimData AnimData;
}
