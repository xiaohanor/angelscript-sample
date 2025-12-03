struct FLocomotionFeatureCopsGunAimOverride2DAnimData
{
	UPROPERTY(Category = "CopsGunAimOverride2D")
	FHazePlaySequenceData HandPose;

	UPROPERTY(Category = "CopsGunAimOverride2D")
	FHazePlaySequenceData TransitionToLeft;

	UPROPERTY(Category = "CopsGunAimOverride2D")
	FHazePlaySequenceData TransitionToRight;

	UPROPERTY(Category = "CopsGunAimOverride2D")
	FHazePlaySequenceData Reload;

	UPROPERTY(Category = "CopsGunAimOverride2D")
	FHazePlayBlendSpaceData AimSpaceRight;

	UPROPERTY(Category = "CopsGunAimOverride2D")
	FHazePlayBlendSpaceData AimSpaceLeft;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlayBlendSpaceData Shoot;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlayBlendSpaceData GrenadeShoot;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlayBlendSpaceData GrenadeDetonate;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlayBlendSpaceData IsOverHeated;


}

class ULocomotionFeatureCopsGunAimOverride2D : UHazeLocomotionFeatureBase
{
	default Tag = n"CopsGunAimOverride2D";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCopsGunAimOverride2DAnimData AnimData;
}
