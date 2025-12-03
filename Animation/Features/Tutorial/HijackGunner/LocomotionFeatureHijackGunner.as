struct FLocomotionFeatureHijackGunnerAnimData
{
	UPROPERTY(Category = "HijackGunner")
	FHazePlayBlendSpaceData AimBS;

	UPROPERTY(Category = "HijackGunner")
	FHazePlayBlendSpaceData ShootBS;
}

class ULocomotionFeatureHijackGunner : UHazeLocomotionFeatureBase
{
	default Tag = n"HijackGunner";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHijackGunnerAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
