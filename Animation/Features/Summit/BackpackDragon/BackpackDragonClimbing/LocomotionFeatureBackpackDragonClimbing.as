struct FLocomotionFeatureBackpackDragonClimbingAnimData
{
	UPROPERTY(Category = "BackpackDragonClimbing")
	FHazePlayBlendSpaceData ClimbEnter;
	
	UPROPERTY(Category = "BackpackDragonClimbing")
	FHazePlaySequenceData ClimbMh;

	UPROPERTY(Category = "BackpackDragonClimbing")
	FHazePlayBlendSpaceData ClimbCharge;

	UPROPERTY(Category = "BackpackDragonClimbing")
	FHazePlayBlendSpaceData ClimbChargeMh;

	UPROPERTY(Category = "BackpackDragonClimbing")
	FHazePlayBlendSpaceData ClimbChargeRelease;

	UPROPERTY(Category = "BackpackDragonClimbing")
	FHazePlayBlendSpaceData ClimbChargeReleaseMh;

	UPROPERTY(Category = "BackpackDragonClimbing")
	FHazePlaySequenceData ClimbExit;
}

class ULocomotionFeatureBackpackDragonClimbing : UHazeLocomotionFeatureBase
{
	default Tag = n"BackpackDragonClimbing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBackpackDragonClimbingAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
