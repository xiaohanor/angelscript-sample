struct FLocomotionFeatureFantasyOtterSwimSurfaceAnimData
{
	UPROPERTY(Category = "Swimming")
	FHazePlayBlendSpaceData SurfaceMh;

	UPROPERTY(Category = "Swimming")
	FHazePlayBlendSpaceData SurfaceSwimStart;

	UPROPERTY(Category = "Swimming")
	FHazePlayBlendSpaceData SurfaceSwimBS;
	
	UPROPERTY(Category = "Swimming")
	FHazePlayBlendSpaceData SurfaceStop;

	UPROPERTY(Category = "Dash")
	FHazePlayBlendSpaceData Dash_Var1;
		
	UPROPERTY(Category = "Diving")
	FHazePlayBlendSpaceData DiveFromSurface;

	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData SurfaceAdditiveBanking;

	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData SurfaceAdditivePitching;


}

class ULocomotionFeatureFantasyOtterSwimSurface : UHazeLocomotionFeatureBase
{
	default Tag = n"SurfaceSwimming";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFantasyOtterSwimSurfaceAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, Category = "Physics")
    UHazePhysicalAnimationProfile PhysAnimProfile;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
