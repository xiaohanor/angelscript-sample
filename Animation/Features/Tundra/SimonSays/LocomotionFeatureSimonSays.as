struct FLocomotionFeatureSimonSaysAnimData
{
	UPROPERTY(Category = "SimonSays")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "SimonSays")
	FHazePlaySequenceData JumpVar1;
	
	UPROPERTY(Category = "SimonSays")
	FHazePlaySequenceData JumpVar2;

	UPROPERTY(Category = "SimonSays")
	FHazePlaySequenceData LandingVar1;

	UPROPERTY(Category = "SimonSays")
	FHazePlaySequenceData LandingVar2;

	UPROPERTY(Category = "SimonSays")
	FHazePlayRndSequenceData Win;

	UPROPERTY(Category = "SimonSays")
	FHazePlayRndSequenceData Fail;

	UPROPERTY(Category = "SimonSays")
	FHazePlayRndSequenceData Falling;
	
	UPROPERTY(Category = "SimonSays|MonkeyKingJumpStrafe")
	FHazePlayBlendSpaceData MonkeyKingJumpStrafe;


}

class ULocomotionFeatureSimonSays : UHazeLocomotionFeatureBase
{
	default Tag = n"SimonSays";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSimonSaysAnimData AnimData;
}
