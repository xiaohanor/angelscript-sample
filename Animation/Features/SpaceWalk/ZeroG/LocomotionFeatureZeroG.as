struct FLocomotionFeatureZeroGAnimData
{
	UPROPERTY(Category = "ZeroG")
	FHazePlayBlendSpaceData StillFloatBS;

	UPROPERTY(Category = "ZeroG")
	FHazePlayBlendSpaceData SlowFloatBS;

	UPROPERTY(Category = "ZeroG")
	FHazePlayBlendSpaceData FastFloatBS;

	UPROPERTY(Category = "ZeroG")
	FHazePlayBlendSpaceData LaunchBodyBS;

	UPROPERTY(Category = "ZeroG")
	FHazePlayBlendSpaceData LaunchLeftArmBS;

	UPROPERTY(Category = "ZeroG")
	FHazePlayBlendSpaceData LaunchRightArmBS;

	UPROPERTY(Category = "ZeroG")
	FHazePlayBlendSpaceData HookLeftArmBS;

	UPROPERTY(Category = "ZeroG")
	FHazePlayBlendSpaceData HookRightArmBS;

	UPROPERTY(Category = "ZeroG")
	FHazePlayBlendSpaceData AdditiveBankingBS;

	
}

class ULocomotionFeatureZeroG : UHazeLocomotionFeatureBase
{
	default Tag = n"ZeroG";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureZeroGAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, Category = "Physics")
    UHazePhysicalAnimationProfile PhysAnimProfile;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph

	
}
