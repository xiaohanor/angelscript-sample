struct FLocomotionFeatureTeenDragonLedgeUpAnimData
{
	UPROPERTY(Category = "TeenDragonLedgeUp")
	FHazePlaySequenceData LedgeUp;

	UPROPERTY(Category = "TeenDragonLedgeUp")
	FHazePlaySequenceData LedgeUpJog;
}

class ULocomotionFeatureTeenDragonLedgeUp : UHazeLocomotionFeatureBase
{
	default Tag = n"TeenDragonLedgeUp";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTeenDragonLedgeUpAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
