struct FLocomotionFeatureExoSuitZoeAnimData
{
	UPROPERTY(Category = "ExoSuit")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "ExoSuit")
	FHazePlaySequenceData Activate;

	UPROPERTY(Category = "ExoSuit")
	FHazePlaySequenceData ActivateMH;
}

class ULocomotionFeatureExoSuitZoe : UHazeLocomotionFeatureBase
{
	default Tag = n"ExoSuit";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureExoSuitZoeAnimData AnimData;
}
