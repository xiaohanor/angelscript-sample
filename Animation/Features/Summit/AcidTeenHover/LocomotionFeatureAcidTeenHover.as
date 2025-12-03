struct FLocomotionFeatureAcidTeenHoverAnimData
{
	UPROPERTY(Category = "Hover")
	FHazePlayBlendSpaceData HoverEnter;

	UPROPERTY(Category = "Hover")
	FHazePlayBlendSpaceData HoverEnterNoBoost;

	UPROPERTY(Category= "Hover")
	FHazePlaySequenceData HoverEnterStill;

	UPROPERTY(Category= "Hover")
	FHazePlaySequenceData HoverEnterStillNoBoost;

	UPROPERTY(Category= "Hover")
	FHazePlaySequenceData HoverMhStill;

	UPROPERTY(Category = "Hover")
	FHazePlayBlendSpaceData HoverBlendSpace;

	UPROPERTY(Category= "Hover")
	FHazePlaySequenceData HoverMovingToStill;
	
	UPROPERTY(Category= "Hover")
	FHazePlayBlendSpaceData HoverStillToMoving;
	
	UPROPERTY(Category= "Hover")
	FHazePlaySequenceData HoverLandStill;

	UPROPERTY(Category= "Hover")
	FHazePlaySequenceData HoverLandRun;

	
}

class ULocomotionFeatureAcidTeenHover : UHazeLocomotionFeatureBase
{
	default Tag = n"AcidTeenHover";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAcidTeenHoverAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
