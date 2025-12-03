struct FLocomotionFeatureSnowMonkeyGrindAnimData
{
	UPROPERTY(Category = "Grind")
	FHazePlaySequenceData MH;
}

class ULocomotionFeatureSnowMonkeyGrind : UHazeLocomotionFeatureBase
{
	default Tag = n"Grind";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyGrindAnimData AnimData;
}
