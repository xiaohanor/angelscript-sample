struct FLocomotionFeatureAdultDragonFlyingAnimData
{
	UPROPERTY(Category = "AdultDragonFlying")
	FHazePlaySequenceData Hover;

	UPROPERTY(Category = "AdultDragonFlying")
	FHazePlayBlendSpaceData StartFlying;

	UPROPERTY(Category = "AdultDragonFlying")
	FHazePlayBlendSpaceData Glide;

	UPROPERTY(Category = "AdultDragonFlying")
	FHazePlayBlendSpaceData Dive;

	UPROPERTY(Category = "AdultDragonFlying")
	FHazePlayBlendSpaceData Dash;

	UPROPERTY(Category = "AdultDragonFlying")
	FHazePlaySequenceData StopFlying;

	UPROPERTY(Category = "Additive | Pitch")
	FHazePlayBlendSpaceData AdditivePitchGlide;

	UPROPERTY(Category = "Additive | Pitch")
	FHazePlayBlendSpaceData AdditivePitchLowerBodyGlide;

	UPROPERTY(Category = "Additive | Banking")
	FHazePlayBlendSpaceData AdditiveBankingGlide;




	UPROPERTY(Category = "Flap")
	FHazePlayRndSequenceData LightFlap;

	UPROPERTY(Category = "Flap")
	FHazePlayRndSequenceData MediumFlap;

	UPROPERTY(Category = "Flap")
	FHazePlayRndSequenceData HeavyFlap;

	UPROPERTY(Category = "Flap")
	FHazePlayBlendSpaceData FlappingFinished;



}

class ULocomotionFeatureAdultDragonFlying : UHazeLocomotionFeatureBase
{
	default Tag = n"AdultDragonFlying";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAdultDragonFlyingAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, Category = "Physics")
    UHazePhysicalAnimationProfile PhysAnimProfile;
}
