struct FLocomotionFeatureBabyDragonClimbingAnimData
{
	
	UPROPERTY(Category = "Climbing")
	FHazePlaySequenceData ClimbEnterStart;

	UPROPERTY(Category = "Climbing")
	FHazePlaySequenceData ClimbEnterMh;

	UPROPERTY(Category = "Climbing")
	FHazePlaySequenceData ClimbEnterGrab;

	UPROPERTY(Category = "Climbing")
	FHazePlaySequenceData ClimbInAirEnterStart;

	UPROPERTY(Category = "Climbing")
	FHazePlaySequenceData ClimbInAirEnterMh;

	UPROPERTY(Category = "Climbing")
	FHazePlaySequenceData ClimbInAirEnterGrab;

	UPROPERTY(Category = "Climbing")
	FHazePlaySequenceData ClimbExit;
	
	UPROPERTY(Category = "Climbing")

	FHazePlayBlendSpaceData ClimbMh;

	UPROPERTY(Category = "Climbing")

	FHazePlayBlendSpaceData ClimbMhReach;

	UPROPERTY(Category = "Climbing")

	FHazePlayBlendSpaceData ClimbGrab;

	UPROPERTY(Category = "Climbing")

	FHazePlayBlendSpaceData ClimbJump;

	UPROPERTY(Category = "Climbing")

	FHazePlayBlendSpaceData ClimbJumpMh;
}

class ULocomotionFeatureBabyDragonClimbing : UHazeLocomotionFeatureBase
{
	default Tag = n"BabyDragonClimbing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBabyDragonClimbingAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
