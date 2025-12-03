struct FLocomotionFeatureControlledBabyDragonDashAnimData
{
	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData Dash;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData ExitToMH;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData ExitToMovement;
}

class ULocomotionFeatureControlledBabyDragonDash : UHazeLocomotionFeatureBase
{
	default Tag = n"Dash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureControlledBabyDragonDashAnimData AnimData;
}
