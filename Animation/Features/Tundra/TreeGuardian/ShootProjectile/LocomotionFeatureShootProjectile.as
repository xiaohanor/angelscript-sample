struct FLocomotionFeatureShootProjectileAnimData
{
	UPROPERTY(Category = "ShootProjectile")
	FHazePlaySequenceData Shoot;
}

class ULocomotionFeatureShootProjectile : UHazeLocomotionFeatureBase
{
	default Tag = n"ShootProjectile";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureShootProjectileAnimData AnimData;
}
