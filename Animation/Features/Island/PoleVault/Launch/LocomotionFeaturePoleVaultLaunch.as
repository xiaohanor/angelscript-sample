struct FLocomotionFeaturePoleVaultLaunchAnimData
{
	UPROPERTY(Category = "PoleVaultLaunch")
	FHazePlaySequenceData Launch;
}

class ULocomotionFeaturePoleVaultLaunch : UHazeLocomotionFeatureBase
{
	default Tag = n"PoleVaultLaunch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePoleVaultLaunchAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
