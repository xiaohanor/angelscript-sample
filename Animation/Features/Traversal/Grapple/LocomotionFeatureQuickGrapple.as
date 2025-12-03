struct FLocomotionFeatureQuickGrappleAnimData
{
	UPROPERTY(Category = "Throw")
	FHazePlaySequenceData ThrowFwd;
	
	UPROPERTY(Category = "Pull")
	FHazePlaySequenceData PullFwd;
}

class ULocomotionFeatureQuickGrapple : UHazeLocomotionFeatureBase
{
	default Tag = n"QuickGrapple";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureQuickGrappleAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
