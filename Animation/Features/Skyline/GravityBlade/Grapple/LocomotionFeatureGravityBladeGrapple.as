struct FLocomotionFeatureGravityBladeGrappleAnimData
{
	UPROPERTY(Category = "GravityBladeGrapple|Grounded")
	FHazePlayBlendSpaceData Throw;

	UPROPERTY(Category = "GravityBladeGrapple|Grounded")
	FHazePlayBlendSpaceData Pull;

	UPROPERTY(Category = "GravityBladeGrapple|Grounded")
	FHazePlayBlendSpaceData Transition;

	UPROPERTY(Category = "GravityBladeGrapple|Grounded")
	FHazePlayBlendSpaceData Landing;


	UPROPERTY(Category = "GravityBladeGrapple|InAir")
	FHazePlayBlendSpaceData InAirThrow;

	UPROPERTY(Category = "GravityBladeGrapple|InAir")
	FHazePlayBlendSpaceData InAirPull;

	UPROPERTY(Category = "GravityBladeGrapple|InAir")
	FHazePlayBlendSpaceData InAirTransition;

	UPROPERTY(Category = "GravityBladeGrapple|InAir")
	FHazePlayBlendSpaceData InAirLanding;
	
}

class ULocomotionFeatureGravityBladeGrapple : UHazeLocomotionFeatureBase
{
	default Tag = n"GravityBladeGrapple";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityBladeGrappleAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

enum EHazeGravityBladeGrappleDistanceAnimationType
{
	Short,
	Medium,
	Long,
}


