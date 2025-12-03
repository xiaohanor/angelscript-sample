struct FLocomotionFeatureFlyingCarGunnerBazookaAnimData
{
	UPROPERTY(Category = "FlyingCarGunnerBazooka")
	FHazePlayBlendSpaceData BazookaAimSpaceFront;

	UPROPERTY(Category = "FlyingCarGunnerBazooka")
	FHazePlayBlendSpaceData BazookaAimSpaceBack;

	UPROPERTY(Category = "FlyingCarGunnerBazooka")
	FHazePlaySequenceData BazookaAimSequence;

	UPROPERTY(Category = "FlyingCarGunnerBazooka")
	FHazePlaySequenceData TrLeftFrontToBack;

	UPROPERTY(Category = "FlyingCarGunnerBazooka")
	FHazePlaySequenceData TrRightFrontToBack;

	UPROPERTY(Category = "FlyingCarGunnerBazooka")
	FHazePlaySequenceData TrLeftBackToFront;

	UPROPERTY(Category = "FlyingCarGunnerBazooka")
	FHazePlaySequenceData TrRightBackToFront;
}

class ULocomotionFeatureFlyingCarGunnerBazooka : UHazeLocomotionFeatureBase
{
	default Tag = n"FlyingCarGunnerBazooka";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFlyingCarGunnerBazookaAnimData AnimData;
}
