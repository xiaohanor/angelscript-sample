struct FLocomotionFeatureCongaMovementAnimData
{
	UPROPERTY(Category = "CongaMovement")
	FHazePlaySequenceData DefaultAnimation;

	UPROPERTY(Category = "CongaMovement")
	FHazePlaySequenceData Dance;

	UPROPERTY(Category = "CongaMovement")
	FHazePlayRndSequenceData Pose1;

	UPROPERTY(Category = "CongaMovement")
	FHazePlayRndSequenceData Pose2;

	UPROPERTY(Category = "CongaMovement")
	FHazePlaySequenceData Pose3;

	UPROPERTY(Category = "CongaMovement")
	FHazePlaySequenceData Pose4;

	UPROPERTY(Category = "CongaMovement")
	FHazePlayRndSequenceData WalkPose1;

	UPROPERTY(Category = "CongaMovement")
	FHazePlayRndSequenceData WalkPose2;

	UPROPERTY(Category = "CongaMovement")
	FHazePlaySequenceData WalkPose3;

	UPROPERTY(Category = "CongaMovement")
	FHazePlaySequenceData WalkPose4;

	UPROPERTY(Category = "CongaMovement")
	FHazePlaySequenceData PoseStumble;

	UPROPERTY(Category = "CongaMovement")
	FHazePlaySequenceData HitWall;
}

class ULocomotionFeatureCongaMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"CongaMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCongaMovementAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
