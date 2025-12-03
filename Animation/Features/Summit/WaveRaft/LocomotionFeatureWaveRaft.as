struct FLocomotionFeatureWaveRaftAnimData
{
	UPROPERTY(Category = "WaveRaft")
	FHazePlayBlendSpaceData MhBS;

	UPROPERTY(Category = "WaveRaft")
	FHazePlaySequenceData MhLeft;

	UPROPERTY(Category = "WaveRaft")
	FHazePlaySequenceData MhRight;

	UPROPERTY(Category = "WaveRaft")
	FHazePlaySequenceData BreakLeftEnter;

	UPROPERTY(Category = "WaveRaft")
	FHazePlaySequenceData BreakRighttEnter;

	UPROPERTY(Category = "WaveRaft")
	FHazePlaySequenceData BreakLeftMh;

	UPROPERTY(Category = "WaveRaft")
	FHazePlaySequenceData BreakRightMh;

	UPROPERTY(Category = "WaveRaft")
	FHazePlaySequenceData BreakRightToLeft;

	UPROPERTY(Category = "WaveRaft")
	FHazePlaySequenceData BreakLeftToRight;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData MhPaddleLeft;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData MhPaddleRight;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData RightToLeftPaddle;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData RightToLeftPaddleWaveRaft;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData LeftToRightPaddle;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData LeftToRightPaddleWaveRaft;
	
	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData PaddleLeft;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData PaddleLeftWaveRaft;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData PaddleRight;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData PaddleRightWaveRaft;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData SwitchToLeftSide;

	UPROPERTY(Category = "PaddleRaft")
	FHazePlaySequenceData SwitchToRightSide;
}

class ULocomotionFeatureWaveRaft : UHazeLocomotionFeatureBase
{
	default Tag = n"WaveRaft";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWaveRaftAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
