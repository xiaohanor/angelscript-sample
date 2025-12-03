struct FLocomotionFeatureTeenDragonLedgeDownAnimData
{
	UPROPERTY(Category = "TeenDragonLedgeDown")
	FHazePlaySequenceData LedgeDown;

	UPROPERTY(Category = "TeenDragonLedgeDown")
	FHazePlaySequenceData LedgeDownJog;
}

class ULocomotionFeatureTeenDragonLedgeDown : UHazeLocomotionFeatureBase
{
	default Tag = n"TeenDragonLedgeDown";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTeenDragonLedgeDownAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
