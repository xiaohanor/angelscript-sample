struct FLocomotionFeatureLaunchAnimData
{
	UPROPERTY(Category = "Launch")
	FHazePlayBlendSpaceData LaunchDownwardsLoopBS;

	UPROPERTY(Category = "Launch")
	FHazePlayBlendSpaceData LaunchHorizontalLoopBS;

	UPROPERTY(Category = "Launch")
	FHazePlayBlendSpaceData LaunchUpwardsLoopBS;

}

class ULocomotionFeatureLaunch : UHazeLocomotionFeatureBase
{
	default Tag = n"Launch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLaunchAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, Category = "Physics")
    UHazePhysicalAnimationProfile PhysAnimProfile;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
