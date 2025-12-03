struct FLocomotionFeatureRainbowPigMovementAnimData
{
	UPROPERTY(Category = "RainbowPigMovement")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "RainbowPigMovement")
	FHazePlayBlendSpaceData Locomotion;

	UPROPERTY(Category = "RainbowPigMovement")
	FHazePlaySequenceData Stop;
}

class ULocomotionFeatureRainbowPigMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Movement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRainbowPigMovementAnimData AnimData;

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 400;
}
