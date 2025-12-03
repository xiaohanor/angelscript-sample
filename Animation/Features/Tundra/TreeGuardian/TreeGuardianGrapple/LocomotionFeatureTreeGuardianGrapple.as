struct FLocomotionFeatureTreeGuardianGrappleAnimData
{
	UPROPERTY(Category = "TreeGuardianGrapple")
	FHazePlaySequenceData GrappleStartForward;

	UPROPERTY(Category = "TreeGuardianGrapple")
	FHazePlaySequenceData GrappleAttachForward;

	UPROPERTY(Category = "TreeGuardianGrapple")
	FHazePlaySequenceData GrapplePullForward;

	UPROPERTY(Category = "TreeGuardianGrapple")
	FHazePlaySequenceData GrappleFlyForward;

	UPROPERTY(Category = "TreeGuardianGrapple")
	FHazePlaySequenceData GrappleFlyLand;

	UPROPERTY(Category = "TreeGuardianGrapple")
	FHazePlaySequenceData GrapplePerchMh;

	UPROPERTY(Category = "TreeGuardianGrapple")
	FHazePlaySequenceData Kick;

	
}

class ULocomotionFeatureTreeGuardianGrapple : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianGrapple";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianGrappleAnimData AnimData;
}
