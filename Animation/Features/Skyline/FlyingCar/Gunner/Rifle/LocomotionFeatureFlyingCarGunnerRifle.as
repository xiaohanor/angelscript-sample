struct FLocomotionFeatureFlyingCarGunnerRifleAnimData
{
	UPROPERTY(Category = "FlyingCarGunnerRifle")
	FHazePlayBlendSpaceData RifleAimSpaceFront;

	UPROPERTY(Category = "FlyingCarGunnerRifle")
	FHazePlayBlendSpaceData RifleAimSpaceBack;

	UPROPERTY(Category = "FlyingCarGunnerRifle")
	FHazePlaySequenceData RifleAimSequence;

	UPROPERTY(Category = "FlyingCarGunnerRifle")
	FHazePlaySequenceData Reload;

	UPROPERTY(Category = "FlyingCarGunnerRifle")
	FHazePlaySequenceData TrLeftFrontToBack;

	UPROPERTY(Category = "FlyingCarGunnerRifle")
	FHazePlaySequenceData TrRightFrontToBack;

	UPROPERTY(Category = "FlyingCarGunnerRifle")
	FHazePlaySequenceData TrLeftBackToFront;

	UPROPERTY(Category = "FlyingCarGunnerRifle")
	FHazePlaySequenceData TrRightBackToFront;

	UPROPERTY(Category = "Sit")
	FHazePlaySequenceData SitEnter;

	UPROPERTY(Category = "Sit")
	FHazePlaySequenceData SitMh;

	UPROPERTY(Category = "Sit")
	FHazePlaySequenceData SitExit;
}

class ULocomotionFeatureFlyingCarGunnerRifle : UHazeLocomotionFeatureBase
{
	default Tag = n"FlyingCarGunnerRifle";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFlyingCarGunnerRifleAnimData AnimData;
}
