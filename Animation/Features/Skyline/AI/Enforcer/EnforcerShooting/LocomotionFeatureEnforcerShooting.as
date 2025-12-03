struct FLocomotionFeatureEnforcerShootingAnimData
{
	UPROPERTY(Category = "EnforcerShooting")
	FHazePlayBlendSpaceData Telegraph;

	UPROPERTY(Category = "EnforcerShooting")
	FHazePlayBlendSpaceData Shooting;

	UPROPERTY(Category = "EnforcerShooting")
	FHazePlaySequenceData ThrowGrenade;
}

class ULocomotionFeatureEnforcerShooting : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::EnforcerShooting;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureEnforcerShootingAnimData AnimData;
}
