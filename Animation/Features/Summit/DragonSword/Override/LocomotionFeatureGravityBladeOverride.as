struct FLocomotionFeatureDragonSwordOverrideAnimData
{
	UPROPERTY(Category = "DragonSwordOverride")
	FHazePlaySequenceData Equip;

	UPROPERTY(Category = "DragonSwordOverride")
	FHazePlaySequenceData Unequip;
	
	UPROPERTY(Category = "DragonSwordOverride")
	FHazePlaySequenceData Mh;

	
}

class ULocomotionFeatureDragonSwordOverride : UHazeLocomotionFeatureBase
{
	default Tag = n"DragonSwordOverride";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDragonSwordOverrideAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
