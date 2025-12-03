struct FLocomotionFeaturePaddleRaftFallingAnimData
{
	UPROPERTY(Category = "PaddleRaftFalling")
	FHazePlaySequenceData FallEnterLeftMh;

	UPROPERTY(Category = "PaddleRaftFalling")
	FHazePlaySequenceData FallEnterRightMh;

	UPROPERTY(Category = "PaddleRaftFalling")
	FHazePlaySequenceData FallLeftMh;

	UPROPERTY(Category = "PaddleRaftFalling")
	FHazePlaySequenceData FallRightMh;

	UPROPERTY(Category = "PaddleRaftFalling")
	FHazePlaySequenceData FallLeftLanding;

	UPROPERTY(Category = "PaddleRaftFalling")
	FHazePlaySequenceData FallRightLanding;
}

class ULocomotionFeaturePaddleRaftFalling : UHazeLocomotionFeatureBase
{
	default Tag = n"PaddleRaftFalling";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePaddleRaftFallingAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
