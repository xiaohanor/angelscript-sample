struct FLocomotionFeatureTreeGuardianGrappleFromGrappleAnimData
{
	

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlayBlendSpaceData Start;
 
 	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlayBlendSpaceData Fly;

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlayBlendSpaceData Land;

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlayBlendSpaceData FailStart;

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlayBlendSpaceData FailMh;

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlayBlendSpaceData FailExit;

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlayBlendSpaceData AimInGrappleLeft;

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlayBlendSpaceData AimInGrappleRight;

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlayBlendSpaceData AimInGrappleAll;

	UPROPERTY(Category = "TreeGuardianGrappleFromGrapple")
	FHazePlaySequenceData MhGrapple;
	
}

class ULocomotionFeatureTreeGuardianGrappleFromGrapple : UHazeLocomotionFeatureBase
{
	default Tag = n"TreeGuardianGrappleFromGrapple";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreeGuardianGrappleFromGrappleAnimData AnimData;
}
