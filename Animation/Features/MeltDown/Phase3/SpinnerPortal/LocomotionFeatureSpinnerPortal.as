struct FLocomotionFeatureSpinnerPortalAnimData
{
	UPROPERTY(Category = "SpinnerPortal")
	FHazePlaySequenceData EnterPhase;

	UPROPERTY(Category = "SpinnerPortal")
	FHazePlaySequenceData PhaseMH;

	UPROPERTY(Category = "SpinnerPortal")
	FHazePlaySequenceData ShootEnter;

	UPROPERTY(Category = "SpinnerPortal")
	FHazePlaySequenceData ShootMH;

	UPROPERTY(Category = "SpinnerPortal")
	FHazePlaySequenceData LeftHandShoot;

	UPROPERTY(Category = "SpinnerPortal")
	FHazePlaySequenceData RightHandShoot;

	UPROPERTY(Category = "SpinnerPortal")
	FHazePlaySequenceData ExitPhase;
}

class ULocomotionFeatureSpinnerPortal : UHazeLocomotionFeatureBase
{
	default Tag = n"SpinnerPortal";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSpinnerPortalAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
