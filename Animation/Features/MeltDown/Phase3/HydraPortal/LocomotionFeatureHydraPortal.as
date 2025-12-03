struct FLocomotionFeatureHydraPortalAnimData
{
	UPROPERTY(Category = "HydraPortal")
	FHazePlaySequenceData EnterPhase;
	
	UPROPERTY(Category = "HydraPortal")
	FHazePlaySequenceData PhaseMH;
	
	UPROPERTY(Category = "HydraPortal")
	FHazePlaySequenceData ExitPhase;
}

class ULocomotionFeatureHydraPortal : UHazeLocomotionFeatureBase
{
	default Tag = n"HydraPortal";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHydraPortalAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
