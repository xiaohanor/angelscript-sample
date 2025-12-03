struct FLocomotionFeatureBladeChargeLaserAnimData
{
	UPROPERTY(Category = "BladeChargeLaser")
	FHazePlayBlendSpaceData Blendspace;
}

class ULocomotionFeatureBladeChargeLaser : UHazeLocomotionFeatureBase
{
	default Tag = n"BladeChargeLaser";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBladeChargeLaserAnimData AnimData;
}
