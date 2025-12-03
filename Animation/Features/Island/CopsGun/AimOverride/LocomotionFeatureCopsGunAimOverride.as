struct FLocomotionFeatureCopsGunAimOverrideAnimData
{
	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlaySequenceData HandPose;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlaySequenceData TransitionToLeft;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlaySequenceData TransitionToRight;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlaySequenceData Reload;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlayBlendSpaceData Shoot;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlayBlendSpaceData GrenadeShoot;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlayBlendSpaceData GrenadeDetonate;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlaySequenceData GrenadeDetonateBackwardsRight;
	
	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlaySequenceData GrenadeDetonateSimple;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlaySequenceData OverHeateded;

	UPROPERTY(Category = "CopsGunAimOverride")
	FHazePlayBlendSpaceData AimSpaceSwing;

	UPROPERTY(Category = "3D")
	FHazePlayBlendSpaceData AimSpaceRight;

	UPROPERTY(Category = "3D")
	FHazePlayBlendSpaceData AimSpaceLeft;

	UPROPERTY(Category = "2D")
	FHazePlayBlendSpaceData AimSpace2D;

}

class ULocomotionFeatureCopsGunAimOverride : UHazeLocomotionFeatureBase
{
	default Tag = n"CopsGunAimOverride";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCopsGunAimOverrideAnimData AnimData;
}
