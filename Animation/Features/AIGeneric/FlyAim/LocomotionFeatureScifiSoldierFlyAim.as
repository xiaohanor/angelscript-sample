struct FLocomotionFeatureScifiSoldierFlyAimAnimData
{
	UPROPERTY(Category = "FlyAim")
	FHazePlaySequenceData FlyTakeOff;

	UPROPERTY(Category = "FlyAim")
	FHazePlaySequenceData FlyLand;

	UPROPERTY(Category = "FlyAim")
	FHazePlayBlendSpaceData FlyMHAimBlendSpace;

	UPROPERTY(Category = "FlyAim")
	FHazePlayBlendSpaceData FlyFwdAimBlendSpace;

	UPROPERTY(Category = "FlyAim")
	FHazePlayBlendSpaceData FlyBackAimBlendSpace;

	UPROPERTY(Category = "FlyAim")
	FHazePlayBlendSpaceData FlyLeftAimBlendSpace;

	UPROPERTY(Category = "FlyAim")
	FHazePlayBlendSpaceData FlyRightAimBlendSpace;

}

class ULocomotionFeatureScifiSoldierFlyAim : UHazeLocomotionFeatureBase
{
	default Tag = n"ScifiSoldierFlyAim";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureScifiSoldierFlyAimAnimData AnimData;
}
