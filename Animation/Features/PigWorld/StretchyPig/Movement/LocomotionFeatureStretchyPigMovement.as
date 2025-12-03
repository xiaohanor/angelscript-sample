struct FLocomotionFeatureStretchyPigMovementAnimData
{
	UPROPERTY(Category = "StretchyPigMovement")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "StretchyPigMovement")
	FHazePlayBlendSpaceData Locomotion;

	UPROPERTY(Category = "StretchyPigMovement")
	FHazePlaySequenceData Stop;
}

class ULocomotionFeatureStretchyPigMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Movement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStretchyPigMovementAnimData AnimData;

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 400;
}
