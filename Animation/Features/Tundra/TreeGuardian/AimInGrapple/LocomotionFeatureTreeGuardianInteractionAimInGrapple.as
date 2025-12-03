struct FLocomotionFeatureTreeGuardianInteractionAimInGrappleAnimData
{
	UPROPERTY(Category = "TreeGuardianInteractionAimInGrapple")
	FHazePlayBlendSpaceData AimInGrappleLeft;

	UPROPERTY(Category = "TreeGuardianInteractionAimInGrapple")
	FHazePlayBlendSpaceData AimInGrappleRight;

	UPROPERTY(Category = "TreeGuardianInteractionAimInGrapple")
	FHazePlayBlendSpaceData AimInGrappleAll;

	UPROPERTY(Category = "TreeGuardianInteractionAimInGrapple")
	FHazePlaySequenceData MhGrapple;
}

class ULocomotionFeatureTreeGuardianInteractionAimInGrapple : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianInteractionAimInGrapple";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianInteractionAimInGrappleAnimData AnimData;
}
