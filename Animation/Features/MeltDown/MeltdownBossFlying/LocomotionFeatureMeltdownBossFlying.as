struct FLocomotionFeatureMeltdownBossFlyingAnimData
{
	UPROPERTY(Category = "MeltdownBossFlying")
	FHazePlayBlendSpaceData FlyingBlendSpace;
	UPROPERTY(Category = "MeltdownBossFlying")
	FHazePlayBlendSpaceData DashBlendSpace;
}

class ULocomotionFeatureMeltdownBossFlying : UHazeLocomotionFeatureBase
{
	default Tag = n"MeltdownBossFlying";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMeltdownBossFlyingAnimData AnimData;
}
