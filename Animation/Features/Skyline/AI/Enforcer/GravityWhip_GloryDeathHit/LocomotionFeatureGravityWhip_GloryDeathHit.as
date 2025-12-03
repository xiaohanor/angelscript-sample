struct FLocomotionFeatureGravityWhip_GloryDeathHitAnimData
{
	UPROPERTY(Category = "GravityWhip_GloryDeathHit")
	FHazePlaySequenceData TripSlam;
}

class ULocomotionFeatureGravityWhip_GloryDeathHit : UHazeLocomotionFeatureBase
{
	default Tag = n"GravityWhip_GloryDeathHit";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityWhip_GloryDeathHitAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
