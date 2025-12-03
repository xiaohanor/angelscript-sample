struct FLocomotionFeatureAztecHoldHatAnimData
{
	UPROPERTY(Category = "AztecHoldHat")
	FHazePlaySequenceData Enter;
	
	UPROPERTY(Category = "AztecHoldHat")
	FHazePlaySequenceData Mh;
}

class ULocomotionFeatureAztecHoldHat : UHazeLocomotionFeatureBase
{
	default Tag = n"AztecHoldHat";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAztecHoldHatAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
