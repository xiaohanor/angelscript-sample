struct FLocomotionFeatureNotGravityWhippableAnimData
{
	UPROPERTY(Category = "NotGravityWhippable")
	FHazePlaySequenceData Start;

	
	UPROPERTY(Category = "NotGravityWhippable")
	FHazePlaySequenceData Mh;

	
	UPROPERTY(Category = "NotGravityWhippable")
	FHazePlaySequenceData Stop;
}

class ULocomotionFeatureNotGravityWhippable : UHazeLocomotionFeatureBase
{
	default Tag = n"NotGravityWhippable";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureNotGravityWhippableAnimData AnimData;
}
