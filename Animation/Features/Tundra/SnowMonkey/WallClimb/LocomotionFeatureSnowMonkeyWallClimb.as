struct FLocomotionFeatureSnowMonkeyWallClimbAnimData
{
	UPROPERTY(Category = "SnowMonkeyWallClimb")
	FHazePlayBlendSpaceData ClimbBlendspace;
}

class ULocomotionFeatureSnowMonkeyWallClimb : UHazeLocomotionFeatureBase
{
	default Tag = n"SnowMonkeyWallClimb";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyWallClimbAnimData AnimData;
}
