struct FLocomotionFeatureFairyLandingAnimData
{
	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData ExitToMH;

	UPROPERTY(Category = "Landing")
	FHazePlaySequenceData ExitToMovement;
}

class ULocomotionFeatureFairyLanding : UHazeLocomotionFeatureBase
{
	default Tag = n"Landing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFairyLandingAnimData AnimData;
}
