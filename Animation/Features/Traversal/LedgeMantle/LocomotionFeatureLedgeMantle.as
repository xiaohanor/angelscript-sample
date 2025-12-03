struct FLocomotionFeatureLedgeMantleAnimData
{
	UPROPERTY(Category = "Scramble")
	FHazePlaySequenceData ScrambleToMH;

	UPROPERTY(Category = "Scramble")
	FHazePlaySequenceData ScrambleToRun;

	UPROPERTY(Category = "Scramble")
	FHazePlaySequenceData ScrambleToCrouch;

	UPROPERTY(Category = "Scramble")
	FHazePlaySequenceData ScrambleToCrouchWalk;


	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpToMH;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpToRun;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpToCrouch;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpToCrouchWalk;


	UPROPERTY(Category = "FallLow")
	FHazePlaySequenceData FallLowToMH;

	UPROPERTY(Category = "FallLow")
	FHazePlaySequenceData FallLowToRun;

	UPROPERTY(Category = "FallLow")
	FHazePlaySequenceData FallLowToRunMirror;

	UPROPERTY(Category = "FallLow")
	FHazePlaySequenceData FallLowToCrouch;

	UPROPERTY(Category = "FallLow")
	FHazePlaySequenceData FallLowToCrouchWalk;


	UPROPERTY(Category = "FallHigh")
	FHazePlaySequenceData FallHighToMH;

	UPROPERTY(Category = "FallHigh")
	FHazePlaySequenceData FallHighToRun;

	UPROPERTY(Category = "FallHigh")
	FHazePlaySequenceData FallHighToCrouch;

	UPROPERTY(Category = "FallHigh")
	FHazePlaySequenceData FallHighToCrouchWalk;


	UPROPERTY(Category = "Run")
	FHazePlayBlendSpaceData RunBS;

	UPROPERTY(Category = "Run")
	FHazePlaySequenceData RunExit;


	UPROPERTY(Category = "Roll")
	FHazePlaySequenceData RollToMH;

	UPROPERTY(Category = "Roll")
	FHazePlaySequenceData RollToRun;


	UPROPERTY(Category = "Still")
	FHazePlaySequenceData StillLowToRun;

}

class ULocomotionFeatureLedgeMantle : UHazeLocomotionFeatureBase
{
	default Tag = n"LedgeMantle";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLedgeMantleAnimData AnimData;
}
