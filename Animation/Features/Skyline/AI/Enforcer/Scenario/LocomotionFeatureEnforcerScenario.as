struct FLocomotionFeatureEnforcerScenarioAnimData
{
	UPROPERTY(Category = "Scenario")
	FHazePlaySequenceData HoldGround;
}

class ULocomotionFeatureEnforcerScenario : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::Scenario;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureEnforcerScenarioAnimData AnimData;
}
