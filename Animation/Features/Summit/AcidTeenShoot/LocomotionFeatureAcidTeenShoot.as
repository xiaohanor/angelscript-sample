struct FLocomotionFeatureAcidTeenShootAnimData
{
	UPROPERTY(Category = "AcidTeenShoot")
	FHazePlayBlendSpaceData ShootEnter;

	UPROPERTY(Category = "AcidTeenShoot")
	FHazePlayBlendSpaceData Shoot;

	UPROPERTY(Category = "AcidTeenShoot")
	FHazePlayBlendSpaceData ShootExit;
	
	UPROPERTY(Category = "Aim")
	FHazePlayBlendSpaceData Aim;
}

class ULocomotionFeatureAcidTeenShoot : UHazeLocomotionFeatureBase
{
	default Tag = n"AcidTeenShoot";

	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAcidTeenShootAnimData AnimData;
}
