struct FLocomotionFeatureSnowMonkeyGrindAirMovementAnimData
{
	UPROPERTY(Category = "GrindAirMovement")
	FHazePlaySequenceData Falling;
}

class ULocomotionFeatureSnowMonkeyGrindAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"AirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyGrindAirMovementAnimData AnimData;
}
