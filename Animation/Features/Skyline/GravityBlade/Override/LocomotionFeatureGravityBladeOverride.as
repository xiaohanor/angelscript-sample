struct FLocomotionFeatureGravityBladeOverrideAnimData
{
	UPROPERTY(Category = "GravityBladeOverride")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "GravityBladeOverride")
	FHazePlaySequenceData Run;

	UPROPERTY(Category = "GravityBladeOverride")
	FHazePlayBlendSpaceData MovementBS;
}

class ULocomotionFeatureGravityBladeOverride : UHazeLocomotionFeatureBase
{
	default Tag = n"GravityBladeOverride";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityBladeOverrideAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
