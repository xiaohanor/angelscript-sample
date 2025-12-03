struct FLocomotionFeatureTailTeenDragonAnimData
{
	
	UPROPERTY(Category= "TailTeenDragon")
	FHazePlaySequenceData Mh;
	
	UPROPERTY(Category = "TailTeenDragon")
	FHazePlayBlendSpaceData MovementBlendSpace;

	UPROPERTY(Category= "TailTeenDragon")
	FHazePlaySequenceData RunStart;

	UPROPERTY(Category= "TailTeenDragon")
	FHazePlaySequenceData RunStop;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlayBlendSpaceData SprintBlendSpace;

	UPROPERTY(Category= "TailTeenDragon")
	FHazePlaySequenceData SprintStop;

	UPROPERTY(Category= "TailTeenDragon")
	FHazePlaySequenceData JumpEnter;

	UPROPERTY(Category= "TailTeenDragon")
	FHazePlaySequenceData JumpEnterFalling;

	UPROPERTY(Category= "TailTeenDragon")
	FHazePlaySequenceData JumpMh;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlayBlendSpaceData JumpLandBlendSpace;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlaySequenceData RollEnter;
	
	UPROPERTY(Category = "TailTeenDragon")
	FHazePlaySequenceData RollMH;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlaySequenceData RollExit;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlaySequenceData RollExitRun;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlaySequenceData Attack1;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlaySequenceData AttackSettle1;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlaySequenceData Attack2;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlaySequenceData AttackSettle2;

	UPROPERTY(Category = "TailTeenDragon")
	FHazePlaySequenceData Attack3;
}

class ULocomotionFeatureTailTeenDragon : UHazeLocomotionFeatureBase
{
	default Tag = n"TailTeenDragon";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTailTeenDragonAnimData AnimData;
}
