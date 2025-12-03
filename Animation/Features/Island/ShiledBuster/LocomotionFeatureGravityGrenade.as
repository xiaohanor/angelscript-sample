struct FLocomotionFeatureGravityGrenadeAnimData
{
	UPROPERTY(Category = "GravityGrenade")
	FHazePlayBlendSpaceData RightArm;

	UPROPERTY(Category = "GravityGrenade")
	FHazePlayBlendSpaceData LeftArm;
}

class ULocomotionFeatureGravityGrenade : UHazeLocomotionFeatureBase
{
	default Tag = n"GravityGrenade";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityGrenadeAnimData AnimData;
}
