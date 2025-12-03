struct FLocomotionFeatureDanceShowdownAnimData
{
	UPROPERTY(Category = "DanceShowdown")
	FHazePlayBlendSpaceData DanceBlendSpace;

	UPROPERTY(Category = "Disco")
	FHazePlayRndSequenceData Mh;

	UPROPERTY(Category = "Disco")
	FHazePlayBlendSpaceData DiscoPoseEnter;

	UPROPERTY(Category = "Disco")
	FHazePlayBlendSpaceData DiscoPoseMh;

	UPROPERTY(Category = "Belly")
	FHazePlayBlendSpaceData BellyPoseEnter;

	UPROPERTY(Category = "Belly")
	FHazePlayBlendSpaceData BellyPoseMh;

	UPROPERTY(Category = "BreakDance")
	FHazePlayBlendSpaceData BreakDancePoseEnter;

	UPROPERTY(Category = "BreakDance")
	FHazePlayBlendSpaceData BreakDancePoseMh;

	UPROPERTY(Category = "FaceMonkeyWiggle")
	FHazePlayBlendSpaceData WiggleBS;

	UPROPERTY(Category = "FaceMonkeyIdleLegs")
	FHazePlaySequenceData FaceMonkeyIdleLegs;

	UPROPERTY(Category = "StageTransition")
	FHazePlaySequenceData StageTransitionMh;

	UPROPERTY(Category = "StageTransition")
	FHazePlayRndSequenceData Success;

	UPROPERTY(Category = "StageTransition")
	FHazePlaySequenceData FailStart;

	UPROPERTY(Category = "StageTransition")
	FHazePlaySequenceData FailMh;
}

class ULocomotionFeatureDanceShowdown : UHazeLocomotionFeatureBase
{
	default Tag = n"DanceShowdown";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDanceShowdownAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
