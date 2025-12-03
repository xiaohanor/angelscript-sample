struct FLocomotionFeatureHoverboardAnimData
{
	UPROPERTY(Category = "Hoverboard")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "Hoverboard")
	FHazePlayBlendSpaceData Banking;

	UPROPERTY(Category = "Hoverboard")
	FHazePlayBlendSpaceData LeaningFwdBack;

	UPROPERTY(Category = "Tricks")
	FHazePlayRndSequenceData Tricks;

	UPROPERTY(Category = "Tricks")
	FHazePlayRndSequenceData TrickX;
	
	UPROPERTY(Category = "Tricks")
	FHazePlayRndSequenceData TrickY;

	UPROPERTY(Category = "Tricks")
	FHazePlayRndSequenceData TrickB;

	UPROPERTY(Category = "Hit Wall")
	FHazePlaySequenceData HitWallLeft;
	
	UPROPERTY(Category = "Hit Wall")
	FHazePlaySequenceData HitWallRight;
}

class ULocomotionFeatureHoverboard : UHazeLocomotionFeatureBase
{
	default Tag = n"Hoverboard";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardAnimData AnimData;
}
