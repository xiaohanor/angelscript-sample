struct FLocomotionFeatureFantasyOtterLandingAnimData
{
	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData ExitToMH;

	UPROPERTY(Category = "Landing")
	FHazePlayBlendSpaceData ExitToMovementBS;
}

class ULocomotionFeatureFantasyOtterLanding : UHazeLocomotionFeatureBase
{
	default Tag = n"Landing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFantasyOtterLandingAnimData AnimData;

	// Settings

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;
}
