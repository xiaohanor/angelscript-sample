struct FLocomotionFeatureSeekSlamAnimData
{
	UPROPERTY(Category = "SeekSlam")
	FHazePlaySequenceData PhaseStart;

	UPROPERTY(Category = "SeekSlam")
	FHazePlaySequenceData MH_Mid;

	UPROPERTY(Category = "SeekSlam")
	FHazePlaySequenceData Tell_Mid;

	UPROPERTY(Category = "SeekSlam")
	FHazePlaySequenceData Slam_Mid;

	UPROPERTY(Category = "SeekSlam")
	FHazePlayBlendSpaceData Additive_Tracking;

	UPROPERTY(Category = "SeekSlam")
	FHazePlayBlendSpaceData Additive_Slam;

	UPROPERTY(Category = "SeekSlam")
	FHazePlaySequenceData PhaseFinished;
}

class ULocomotionFeatureSeekSlam : UHazeLocomotionFeatureBase
{
	default Tag = n"SeekSlam";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSeekSlamAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
