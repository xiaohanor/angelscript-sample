struct FLocomotionFeatureAdultDragonRidingAnimData
{
	UPROPERTY(Category = "DragonRiding")
	FHazePlaySequenceData Mh;

}

class ULocomotionFeatureAdultDragonRiding : UHazeLocomotionFeatureBase
{
	default Tag = n"DragonRiding";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAdultDragonRidingAnimData AnimData;
}
