struct FLocomotionFeatureDarkPortalAnimData
{

	UPROPERTY(Category = "Dark Portal")
	FHazePlayBlendSpaceData AimStart;

	UPROPERTY(Category = "Dark Portal")
	FHazePlayBlendSpaceData Aim;

	UPROPERTY(Category = "Dark Portal")
	FHazePlayBlendSpaceData Launch;

	UPROPERTY(Category = "Dark Portal")
	FHazePlaySequenceData GrabStart;

	UPROPERTY(Category = "Dark Portal")
	FHazePlayBlendSpaceData GrabMh;

	UPROPERTY(Category = "Dark Portal")
	FHazePlaySequenceData GrabRelease;

	UPROPERTY(Category = "Dark Portal")
	FHazePlaySequenceData GrabStop;

	UPROPERTY(Category = "Dark Portal")
	FHazePlaySequenceData Release;
}

class ULocomotionFeatureDarkPortal : UHazeLocomotionFeatureBase
{
	default Tag = n"DarkPortal";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDarkPortalAnimData AnimData;
}
