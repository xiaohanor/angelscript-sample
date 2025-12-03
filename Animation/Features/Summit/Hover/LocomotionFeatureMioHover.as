struct FLocomotionFeatureMioHoverAnimData
{
	UPROPERTY(Category = "DoubleJump")
	FHazePlaySequenceData DoubleJump;

	UPROPERTY(Category = "Hover")
	FHazePlaySequenceData HoverEnter;

	UPROPERTY(Category = "Hover")
	FHazePlaySequenceData HoverMh;

	UPROPERTY(Category = "Hover")
	FHazePlaySequenceData HoverExit;
}

class ULocomotionFeatureMioHover : UHazeLocomotionFeatureBase
{
	default Tag = n"MioHover";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMioHoverAnimData AnimData;
}
