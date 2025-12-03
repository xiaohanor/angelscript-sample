struct FLocomotionFeatureEnforcerRipArmourAnimData
{
	UPROPERTY(Category = "EnforcerRipArmour")
	FHazePlaySequenceData RipLeft;

	UPROPERTY(Category = "EnforcerRipArmour")
	FHazePlaySequenceData RipRight;
}

class ULocomotionFeatureEnforcerRipArmour : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::EnforcerRipArmour;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureEnforcerRipArmourAnimData AnimData;
}
