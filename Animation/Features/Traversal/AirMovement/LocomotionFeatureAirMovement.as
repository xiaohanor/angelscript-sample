struct FLocomotionFeatureAirMovementAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Enter")
	FHazePlayBlendSpaceData FallEnterLeftBS;

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
	FHazePlayBlendSpaceData FallEnterRightBS;

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
	FHazePlayRndSequenceData SwapToRightFootForward;

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
	FHazePlayBlendSpaceData SwapToRightFootForwardBS;

	UPROPERTY(BlueprintReadOnly, Category = "AirMovement")
	FHazePlaySequenceData FallMh;

	UPROPERTY(BlueprintReadOnly, Category = "AirMovement")
	FHazePlaySequenceData FallFatalMh;

	UPROPERTY(BlueprintReadOnly, Category = "AirMovement")
	FHazePlaySequenceData ToFatal;

	UPROPERTY(BlueprintReadOnly, Category = "AirMovement")
	FHazePlaySequenceData ToFatalFromSpringOff;

	UPROPERTY(BlueprintReadOnly, Category = "AirMovement")
	FHazePlayBlendSpaceData FallingBS;

	UPROPERTY(BlueprintReadOnly, Category = "AirMovement")
	FHazePlayBlendSpaceData UpwardsBS;
}

class ULocomotionFeatureAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"AirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAirMovementAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
