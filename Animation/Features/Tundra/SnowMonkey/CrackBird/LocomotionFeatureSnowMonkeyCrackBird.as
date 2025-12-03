struct FLocomotionFeatureSnowMonkeyCrackBirdAnimData
{
	UPROPERTY(Category = "PickUpBird")
	FHazePlaySequenceData PickUpBird;

	UPROPERTY(Category = "PickUpBird")
	FHazePlaySequenceData MhBird;

	UPROPERTY(Category = "PickUpBird")
	FHazePlayBlendSpaceData LocomotionStartBird;

	UPROPERTY(Category = "PickUpBird")
	FHazePlayBlendSpaceData LocomotionBird;

	UPROPERTY(Category = "PickUpBird")
	FHazePlayBlendSpaceData LocomotionStopBird;

	UPROPERTY(Category = "PickUpBird")
	FHazePlaySequenceData PutDownBird;
}

class ULocomotionFeatureSnowMonkeyCrackBird : UHazeLocomotionFeatureBase
{
	default Tag = n"PickUpBird";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePickUpBirdAnimData AnimData;

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;
}
