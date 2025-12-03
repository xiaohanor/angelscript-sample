struct FLocomotionFeatureAztecSwapAnimData
{
	UPROPERTY(Category = "AztecSwap")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "AztecSwap")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "AztecSwap")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureAztecSwap : UHazeLocomotionFeatureBase
{
	default Tag = n"AztecSwap";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAztecSwapAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
