struct FLocomotionFeatureEnforcerExposedAnimData
{
	UPROPERTY(Category = "Exposed")
	FHazePlaySequenceData ExposedStart;

	UPROPERTY(Category = "Exposed")
	FHazePlaySequenceData ExposedMH;

	UPROPERTY(Category = "Exposed")
	FHazePlaySequenceData ExposedEnd;

	UPROPERTY(Category = "Damaged")
	FHazePlaySequenceData DamagedStart;

	UPROPERTY(Category = "Damaged")
	FHazePlayRndSequenceData HitReaction;

	UPROPERTY(Category = "Damaged")
	FHazePlaySequenceData DamagedEnd;
}

class ULocomotionFeatureEnforcerExposed : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::Exposed;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureEnforcerExposedAnimData AnimData;
}
