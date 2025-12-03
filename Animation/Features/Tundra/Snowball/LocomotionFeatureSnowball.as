struct FLocomotionFeatureSnowballAnimData
{
	UPROPERTY(Category = "Snowball")
	FHazePlaySequenceData Pickup;

	UPROPERTY(Category = "Snowball")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Snowball")
	FHazePlaySequenceData MovingMh;

	UPROPERTY(Category = "Snowball")
	FHazePlaySequenceData Throw;
}

class ULocomotionFeatureSnowball : UHazeLocomotionFeatureBase
{
	default Tag = n"Snowball";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowballAnimData AnimData;
}
