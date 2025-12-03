struct FLocomotionFeatureTailTeenClimbAnimData
{
	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData EnterStart;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData EnterMh;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData EnterGrab;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData EnterInAir;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData ExitMantle;
	
	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData ClimbStart;
	
	UPROPERTY(Category = "TailTeenClimb")
	FHazePlayBlendSpaceData Climb;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData ClimbStop;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData ClimbExit;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData  DashEnter;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData  DashMh;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData  DashExit;

	UPROPERTY(Category = "TailTeenClimb")
	FHazePlaySequenceData  DashExitLoco;
}

class ULocomotionFeatureTailTeenClimb : UHazeLocomotionFeatureBase
{
	default Tag = n"TailTeenClimb";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTailTeenClimbAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
