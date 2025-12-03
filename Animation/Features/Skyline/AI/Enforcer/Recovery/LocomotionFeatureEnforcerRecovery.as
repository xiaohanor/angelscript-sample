struct FLocomotionFeatureEnforcer_RecoveryAnimData
{
	UPROPERTY(Category = "Enforcer_Recovery")
	FHazePlaySequenceData Recovery;
}

class ULocomotionFeatureEnforcer_Recovery : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::Enforcer_Recovery;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureEnforcer_RecoveryAnimData AnimData;
}
