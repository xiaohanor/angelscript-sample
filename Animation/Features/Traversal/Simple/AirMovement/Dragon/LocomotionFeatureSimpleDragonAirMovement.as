struct FLocomotionFeatureSimpleDragonAirMovementAnimData
{
	UPROPERTY(Category = "AirMovement")
	FHazePlayBlendSpaceData Falling;
}

class ULocomotionFeatureSimpleDragonAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"AirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSimpleDragonAirMovementAnimData AnimData;

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;
}
