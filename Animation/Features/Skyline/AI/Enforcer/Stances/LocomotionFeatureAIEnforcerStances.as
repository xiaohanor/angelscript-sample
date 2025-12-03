struct FLocomotionFeatureAIEnforcerStancesAnimData
{
	UPROPERTY(Category = "EnforcerStances")
	FHazePlaySequenceData DefensiveStance;

	UPROPERTY(Category = "EnforcerStances")
	FHazePlaySequenceData AimToDefensiveStance;

	UPROPERTY(Category = "EnforcerStances")
	FHazePlaySequenceData DefensiveStanceToMH;

	UPROPERTY(Category = "EnforcerStances")
	FHazePlaySequenceData DefensiveStanceToAim;
}

class ULocomotionFeatureAIEnforcerStances : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::EnforcerStances;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAIEnforcerStancesAnimData AnimData;
}
