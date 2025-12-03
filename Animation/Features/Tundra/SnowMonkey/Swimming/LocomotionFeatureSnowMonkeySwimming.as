struct FLocomotionFeatureSnowMonkeySwimmingAnimData
{
	UPROPERTY(Category = "Swimming")
	FHazePlaySequenceData Drown;
}

class ULocomotionFeatureSnowMonkeySwimming : UHazeLocomotionFeatureBase
{
	default Tag = n"UnderwaterSwimming";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeySwimmingAnimData AnimData;
}
