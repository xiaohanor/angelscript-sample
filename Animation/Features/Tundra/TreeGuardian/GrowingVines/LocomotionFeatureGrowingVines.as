struct FLocomotionFeatureGrowingVinesAnimData
{


	UPROPERTY(Category = "GrowingVines")
	FHazePlayBlendSpaceData LookAimPitch;


	UPROPERTY(Category = "GrowingVines")
	FHazePlayBlendSpaceData AimGrapple;

	UPROPERTY(Category = "GrowingVines")
	FHazePlayBlendSpaceData AimGrowVines;

	
	

	
}

class ULocomotionFeatureGrowingVines : UHazeLocomotionFeatureBase
{
	default Tag = n"GrowingVines";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGrowingVinesAnimData AnimData;
}
