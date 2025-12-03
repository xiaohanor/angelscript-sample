struct FLocomotionFeatureAFKIdleAnimData
{
	UPROPERTY(Category = "AFKIdle")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "AFKIdle")
	FHazePlaySequenceData MH;
}

class ULocomotionFeatureAFKIdle : UHazeLocomotionFeatureBase
{
	default Tag = n"AFKIdle";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAFKIdleAnimData AnimData;
}
