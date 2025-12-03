struct FLocomotionFeatureAcidTeenAirCurrentAnimData
{
	UPROPERTY(Category = "AcidTeenAirCurrent")
	FHazePlaySequenceData EnterAirCurrent;

	UPROPERTY(Category = "AcidTeenAirCurrent")
	FHazePlaySequenceData EnterAirCurrentStill;
}

class ULocomotionFeatureAcidTeenAirCurrent : UHazeLocomotionFeatureBase
{
	default Tag = n"AcidTeenAirCurrent";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAcidTeenAirCurrentAnimData AnimData;
}
