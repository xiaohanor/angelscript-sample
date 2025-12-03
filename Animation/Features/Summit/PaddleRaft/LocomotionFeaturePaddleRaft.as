struct FLocomotionFeaturePaddleRaftAnimData
{
	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData MhLeft;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData MhRight;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData RightToLeftPaddle;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData LeftToRightPaddle;
	
	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData PaddleLeft;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlayRndSequenceData PaddleLeftRnd;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData PaddleRight;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlayRndSequenceData PaddleRightRnd;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData SwitchToLeftSide;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData SwitchToRightSide;

	
}

class ULocomotionFeaturePaddleRaft : UHazeLocomotionFeatureBase
{
	default Tag = n"PaddleRaft";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePaddleRaftAnimData AnimData;
}
