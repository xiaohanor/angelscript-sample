struct FLocomotionFeatureSanctuaryDoppelgangerPauseAnimData
{
	UPROPERTY(Category = "Attack")
	FHazePlayRndSequenceData PauseMHs;
}

class ULocomotionFeatureSanctuaryDoppelgangerPause : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISanctuaryTags::DoppelgangerCreepyPause;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSanctuaryDoppelgangerPauseAnimData AnimData;
}
