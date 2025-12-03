struct FLocomotionFeatureTaillTeenPullAnimData
{
	UPROPERTY(Category = "TaillTeenPull")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "TaillTeenPull")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "TaillTeenPull")
	FHazePlayBlendSpaceData Start;
	
	UPROPERTY(Category = "TaillTeenPull")
	FHazePlayBlendSpaceData Pull;

	UPROPERTY(Category = "TaillTeenPull")
	FHazePlayBlendSpaceData Stop;

	UPROPERTY(Category = "TaillTeenPull")
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "TaillTeenPull")
	FHazePlaySequenceData ExitPulled;
}

class ULocomotionFeatureTaillTeenPull : UHazeLocomotionFeatureBase
{
	default Tag = n"TaillTeenPull";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTaillTeenPullAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
