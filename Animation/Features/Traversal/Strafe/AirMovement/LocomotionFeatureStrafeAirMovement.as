struct FLocomotionFeatureStrafeAirMovementAnimData
{

	UPROPERTY(Category = "StrafeAir")
	FHazePlaySequenceData StrafeAirEnter;	

	UPROPERTY(Category = "StrafeAir")
	FHazePlayBlendSpaceData StrafeAirMoveBS;
}

class ULocomotionFeatureStrafeAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"StrafeAir";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStrafeAirMovementAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
