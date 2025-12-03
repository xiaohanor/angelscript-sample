struct FLocomotionFeatureFairyJumpAnimData
{
	UPROPERTY(Category = "FairyJump")
	FHazePlaySequenceData Jump1;

	UPROPERTY(Category = "FairyJump")
	FHazePlaySequenceData Jump2;

	UPROPERTY(Category = "FairyJump")
	FHazePlaySequenceData Jump3;

	UPROPERTY(Category = "FairyJump")
	FHazePlaySequenceData Jump4;

	UPROPERTY(Category = "FairyJump")
	FHazePlaySequenceData Jump5;


	UPROPERTY(Category = "FairyJump")
	FHazePlayRndSequenceData  Dash;

	UPROPERTY(Category = "FairyJump")
	FHazePlaySequenceData  ToAirMovemt;

	
}

class ULocomotionFeatureFairyJump : UHazeLocomotionFeatureBase
{
	default Tag = n"Jump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFairyJumpAnimData AnimData;
}
