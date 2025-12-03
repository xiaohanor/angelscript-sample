struct FLocomotionFeatureWallScrambleAnimData
{
	UPROPERTY(Category = "WallScramble")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "WallScramble")
	FHazePlaySequenceData Loop;

	UPROPERTY(Category = "WallScramble")
	FHazePlaySequenceData Cancel;

	UPROPERTY(Category = "WallScramble")
	FHazePlayBlendSpaceData Jump;
}

class ULocomotionFeatureWallScramble : UHazeLocomotionFeatureBase
{
	default Tag = n"WallScramble";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWallScrambleAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
