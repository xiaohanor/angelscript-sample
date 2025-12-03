struct FLocomotionFeatureFlyingCar_GunnerAnimData
{
	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlayBlendSpaceData RifleAimSpaceFront;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlayBlendSpaceData RifleAimSpaceBack;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlaySequenceData RifleADS;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlaySequenceData RifleReload;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlaySequenceData RifleTransitionToSit;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlaySequenceData RifleFront;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlaySequenceData RifleBack;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlaySequenceData RifleTrLeftFrontToBack;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlaySequenceData RifleTrLeftBackToFront;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlaySequenceData RifleTrRightFrontToBack;

	UPROPERTY(Category = "FlyingCar_Gunner_Rifle")
	FHazePlaySequenceData RifleTrRightBackToFront;

	UPROPERTY(Category = "FlyingCar_Gunner_Bazooka")
	FHazePlayBlendSpaceData BazookaAimSpace;

	UPROPERTY(Category = "FlyingCar_Gunner_Bazooka")
	FHazePlaySequenceData BazookaADS;

	UPROPERTY(Category = "FlyingCar_Gunner_Bazooka")
	FHazePlaySequenceData BazookaReload;

	UPROPERTY(Category = "FlyingCar_Gunner_Bazooka")
	FHazePlaySequenceData BazookaTransitionToSit;

	UPROPERTY(Category = "FlyingCar_Gunner")
	FHazePlaySequenceData Sitting;
}

class ULocomotionFeatureFlyingCar_Gunner : UHazeLocomotionFeatureBase
{
	default Tag = n"FlyingCar_Gunner";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFlyingCar_GunnerAnimData AnimData;
}
