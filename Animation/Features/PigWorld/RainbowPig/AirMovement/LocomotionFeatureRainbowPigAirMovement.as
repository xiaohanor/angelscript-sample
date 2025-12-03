struct FLocomotionFeatureRainbowPigAirMovementAnimData
{
	UPROPERTY(Category = "RainbowPigAirMovement")
	FHazePlaySequenceData Falling;
}

class ULocomotionFeatureRainbowPigAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"AirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRainbowPigAirMovementAnimData AnimData;
}
