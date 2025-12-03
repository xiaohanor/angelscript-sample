struct FLocomotionFeatureCentipedeRidingAnimData
{
	UPROPERTY(Category = "CentipedeRiding")
	FHazePlayBlendSpaceData MovementStartBs;

	UPROPERTY(Category = "CentipedeRiding")
	FHazePlayBlendSpaceData MovementBs;
}

class ULocomotionFeatureCentipedeRiding : UHazeLocomotionFeatureBase
{
	default Tag = n"CentipedeRiding";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCentipedeRidingAnimData AnimData;
}
