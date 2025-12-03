struct FLocomotionFeatureSimpleAirMovementAnimData
{
	UPROPERTY(Category = "AirMovement")
	FHazePlayBlendSpaceData Falling;
}

class ULocomotionFeatureSimpleAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"AirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSimpleAirMovementAnimData AnimData;

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;
}
