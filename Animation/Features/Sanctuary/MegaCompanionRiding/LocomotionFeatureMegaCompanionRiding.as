struct FLocomotionFeatureMegaCompanionRidingAnimData
{
	UPROPERTY(Category = "MegaCompanionRiding")
	FHazePlaySequenceData Mh;
}

class ULocomotionFeatureMegaCompanionRiding : UHazeLocomotionFeatureBase
{
	default Tag = n"MegaCompanionRiding";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMegaCompanionRidingAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
