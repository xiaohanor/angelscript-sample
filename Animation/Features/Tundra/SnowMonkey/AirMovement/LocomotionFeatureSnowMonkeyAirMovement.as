struct FLocomotionFeatureSnowMonkeyAirMovementAnimData
{
	UPROPERTY(Category = "SnowMonkeyAirMovement")
	FHazePlaySequenceData Falling;
}

class ULocomotionFeatureSnowMonkeyAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"AirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyAirMovementAnimData AnimData;
}
