struct FLocomotionFeatureTreeGuardianInteractionAimAnimData
{
	UPROPERTY(Category = "TreeGuardianInteractionAim")
	FHazePlayBlendSpaceData AimInteraction;

	UPROPERTY(Category = "TreeGuardianInteractionAim")
	FHazePlayBlendSpaceData AimGrapple;

	UPROPERTY(Category = "TreeGuardianInteractionAim")
	FHazePlayBlendSpaceData AimGrowVines;

	
}

class ULocomotionFeatureTreeGuardianInteractionAim : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianInteractionAim";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianInteractionAimAnimData AnimData;
}
