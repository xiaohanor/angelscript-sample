struct FLocomotionFeatureAdultDragonStrafeAnimData
{

	UPROPERTY(Category = "AdultDragonStrafe")
	FHazePlayBlendSpaceData Glide;

	UPROPERTY(Category = "AdultDragonStrafe")
	FHazePlayBlendSpaceData Dash;


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

class ULocomotionFeatureAdultDragonStrafe : UHazeLocomotionFeatureBase
{
	default Tag = n"AdultDragonStrafe";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAdultDragonStrafeAnimData AnimData;
}
