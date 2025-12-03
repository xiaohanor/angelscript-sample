struct FLocomotionFeatureSlidingDiscAnimData
{
	UPROPERTY(Category = "SlidingDisc")
	FHazePlaySequenceData SlideMh;

	UPROPERTY(Category = "SlidingDisc")
	FHazePlaySequenceData MoveRight;

	UPROPERTY(Category = "SlidingDisc")
	FHazePlaySequenceData MoveLeft;

	UPROPERTY(Category = "SlidingDisc")
	FHazePlaySequenceData Shuffle;

	UPROPERTY(Category = "SlidingDisc")
	FHazePlayBlendSpaceData BSShuffleMh;

	UPROPERTY(Category = "SlidingDisc")
	FHazePlayBlendSpaceData BSImpact;

}

class ULocomotionFeatureSlidingDisc : UHazeLocomotionFeatureBase
{
	default Tag = n"SlidingDisc";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSlidingDiscAnimData AnimData;
}
