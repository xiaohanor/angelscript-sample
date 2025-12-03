struct FLocomotionFeaturePickUpAnimData
{
	UPROPERTY(Category = "Light")
	FHazePlaySequenceData PickUpGroundLight;

	UPROPERTY(Category = "Light")
	FHazePlaySequenceData BackpackPosition;

	UPROPERTY(Category = "Light")
	FHazePlaySequenceData PutDownGroundLight;
	
	
	UPROPERTY(Category = "Heavy")
	FHazePlaySequenceData PickUpGroundHeavy;

	UPROPERTY(Category = "Heavy")
	FHazePlaySequenceData CarryHeavy;

	UPROPERTY(Category = "Heavy")
	FHazePlaySequenceData GroundPutDownHeavy;
}

class ULocomotionFeaturePickUp : UHazeLocomotionFeatureBase
{
	default Tag = n"PickUp";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePickUpAnimData AnimData;
}
