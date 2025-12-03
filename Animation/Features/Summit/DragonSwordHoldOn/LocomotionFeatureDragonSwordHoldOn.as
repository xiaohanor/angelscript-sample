struct FLocomotionFeatureDragonSwordHoldOnAnimData
{
	UPROPERTY(Category = "DragonSwordHoldOn")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "DragonSwordHoldOn")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "DragonSwordHoldOn")
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "DragonSwordHoldOn")
	FHazePlaySequenceData ExitToLoco;
}

class ULocomotionFeatureDragonSwordHoldOn : UHazeLocomotionFeatureBase
{
	default Tag = n"DragonSwordHoldOn";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDragonSwordHoldOnAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
