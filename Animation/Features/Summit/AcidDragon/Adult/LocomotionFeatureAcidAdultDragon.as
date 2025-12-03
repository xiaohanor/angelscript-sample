struct FLocomotionFeatureAcidAdultDragonAnimData
{
	UPROPERTY(Category = "AcidAdultDragon")
	FHazePlayBlendSpaceData DefaultBlendSpace;
}

class ULocomotionFeatureAcidAdultDragon : UHazeLocomotionFeatureBase
{
	default Tag = n"AcidAdultDragon";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAcidAdultDragonAnimData AnimData;
}
