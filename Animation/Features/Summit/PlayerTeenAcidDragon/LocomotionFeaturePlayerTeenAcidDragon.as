struct FLocomotionFeaturePlayerTeenAcidDragonAnimData
{
	UPROPERTY(Category = "Mio")
	FHazePlaySequenceData Mh;
}

class ULocomotionFeaturePlayerTeenAcidDragon : UHazeLocomotionFeatureBase
{
	default Tag = n"PlayerTeenAcidDragon";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePlayerTeenAcidDragonAnimData AnimData;
}
