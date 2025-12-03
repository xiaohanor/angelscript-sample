struct FLocomotionFeatureMechPortalAnimData
{
	UPROPERTY(Category = "MechPortal")
	FHazePlaySequenceData BeginPhase;

	UPROPERTY(Category = "MechPortal")
	FHazePlaySequenceData BeginPhaseFast;

	UPROPERTY(Category = "MechPortal")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "MechPortal")
	FHazePlaySequenceData ThrowLeftHand;

	UPROPERTY(Category = "MechPortal")
	FHazePlaySequenceData ThrowRightHand;

	UPROPERTY(Category = "MechPortal")
	FHazePlaySequenceData EndPhase;
}

class ULocomotionFeatureMechPortal : UHazeLocomotionFeatureBase
{
	default Tag = n"MechPortal";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMechPortalAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
