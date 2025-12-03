struct FLocomotionFeatureSwimSurfaceAnimData
{
	UPROPERTY(Category = "SwimSurface")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "SwimSurface")
	FHazePlayBlendSpaceData FreestyleStart;

	UPROPERTY(Category = "SwimSurface")
	FHazePlayBlendSpaceData FreestyleSwimming;

	UPROPERTY(Category = "SwimSurface")
	FHazePlaySequenceData FreestyleStop;

	UPROPERTY(Category = "SwimSurface")
	FHazePlaySequenceData LedgeUp;

	UPROPERTY(Category = "SwimSurface")
	FHazePlayBlendSpaceData AdditiveBankingBS;

	UPROPERTY(Category = "SurfaceToUnderwater")
	FHazePlaySequenceData DiveFromSurface;

	UPROPERTY(Category = "SurfaceToUnderwater")
	FHazePlayBlendSpaceData AdditivePitchBS;

	UPROPERTY(Category = "Jump")
	FHazePlayBlendSpaceData SurfaceJumpOutBS;

}

class ULocomotionFeatureSwimSurface : UHazeLocomotionFeatureBase
{
	default Tag = n"SurfaceSwimming";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSwimSurfaceAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
