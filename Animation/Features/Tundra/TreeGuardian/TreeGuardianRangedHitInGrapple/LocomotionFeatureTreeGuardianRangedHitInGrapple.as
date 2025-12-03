struct FLocomotionFeatureTreeGuardianRangedHitInGrappleAnimData
{
	UPROPERTY(Category = "TreeGuardianRangedHitInGrapple")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "TreeGuardianRangedHitInGrapple")
	FHazePlayBlendSpaceData Start;

	UPROPERTY(Category = "TreeGuardianRangedHitInGrapple")
	FHazePlayBlendSpaceData MhFail;

	
	UPROPERTY(Category = "TreeGuardianRangedHitInGrapple")
	FHazePlayBlendSpaceData Exit;
}

class ULocomotionFeatureTreeGuardianRangedHitInGrapple : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianRangedHitInGrapple";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianRangedHitInGrappleAnimData AnimData;
}
