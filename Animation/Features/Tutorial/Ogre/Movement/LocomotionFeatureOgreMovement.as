struct FLocomotionFeatureOgreMovementAnimData
{

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData RunStartBS;

	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData RunBS;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData RunStop;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData Jump;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData Fall;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData LandToMH;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData LandToRun1000;


	UPROPERTY(Category = "BreakWall")
	FHazePlaySequenceData BreakWallToMH;

	UPROPERTY(Category = "BreakWall")
	FHazePlayBlendSpaceData BreakWallToRunBS;

	UPROPERTY(Category = "BreakWall")
	FHazePlaySequenceData BreakWallToMHMirror;

	UPROPERTY(Category = "BreakWall")
	FHazePlayBlendSpaceData BreakWallToRunBSMirror;

	UPROPERTY(Category = "BreakWall")
	FHazePlaySequenceData BreakWallToHurt;

	UPROPERTY(Category = "BreakWall")
	FHazePlaySequenceData BreakWallHurtMH;

}

class ULocomotionFeatureOgreMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Movement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureOgreMovementAnimData AnimData;
}