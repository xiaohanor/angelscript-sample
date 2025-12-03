struct FLocomotionFeatureBackpackDragonMovementAnimData
{
	UPROPERTY(Category = "BackpackDragonMovement")
	FHazePlaySequenceData Mh;
	
	UPROPERTY(Category = "BackpackDragonMovement")
	FHazePlaySequenceData Movement;
}

class ULocomotionFeatureBackpackDragonMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"BackpackDragonMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBackpackDragonMovementAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly)
	UHazePhysicalAnimationProfile PhysAnimProfile;
}
