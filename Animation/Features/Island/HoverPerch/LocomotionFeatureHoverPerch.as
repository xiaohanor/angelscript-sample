struct FLocomotionFeatureHoverPerchAnimData
{
	UPROPERTY(Category = "HoverPerch")
	FHazePlayBlendSpaceData Enter;

	UPROPERTY(Category = "HoverPerch")
	FHazePlaySequenceData EnterLanding;

	UPROPERTY(Category = "HoverPerch")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "HoverPerch")
	FHazePlayBlendSpaceData UnstableMh;

	UPROPERTY(Category = "HoverPerch")
	FHazePlaySequenceData Jump;

	UPROPERTY(Category = "HoverPerch")
	FHazePlaySequenceData Landing;

	UPROPERTY(Category = "HoverPerch")
	FHazePlaySequenceData Dash;

	UPROPERTY(Category = "HoverPerch")
	FHazePlaySequenceData Bump;

	UPROPERTY(Category = "HoverPerch")
	FHazePlaySequenceData Grind;
}

class ULocomotionFeatureHoverPerch : UHazeLocomotionFeatureBase
{
	default Tag = n"Perch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverPerchAnimData AnimData;
}
