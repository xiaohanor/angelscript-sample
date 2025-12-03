struct FLocomotionFeatureBarrelThrowAnimData
{
	UPROPERTY(Category = "BarrelThrow")
	FHazePlaySequenceData ThrowLeft;
	UPROPERTY(Category = "BarrelThrow")
	FHazePlaySequenceData ThrowRight;
	
}

class ULocomotionFeatureBarrelThrow : UHazeLocomotionFeatureBase
{
	default Tag = n"BarrelThrow";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBarrelThrowAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
