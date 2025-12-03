struct FLocomotionFeatureDragonStumbleAnimData
{
	UPROPERTY(Category = "DragonStumble")
	FHazePlaySequenceData StumbleBack;
}

class ULocomotionFeatureDragonStumble : UHazeLocomotionFeatureBase
{
	default Tag = n"DragonStumble";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDragonStumbleAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
