struct FLocomotionFeatureGunSwapAnimData
{
	UPROPERTY(Category = "GunSwap")
	FHazePlaySequenceData GunSwap;
}

class ULocomotionFeatureGunSwap : UHazeLocomotionFeatureBase
{
	default Tag = n"GunSwap";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGunSwapAnimData AnimData;
}
