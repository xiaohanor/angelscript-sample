struct FLocomotionFeatureGravityWhip_GloryKillHitAnimData
{
	UPROPERTY(Category = "GravityWhip_GloryKillHit")
	FHazePlaySequenceData TripSlam;
}

class ULocomotionFeatureGravityWhip_GloryKillHit : UHazeLocomotionFeatureBase
{
	default Tag = n"GravityWhip_GloryKillHit";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityWhip_GloryKillHitAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
