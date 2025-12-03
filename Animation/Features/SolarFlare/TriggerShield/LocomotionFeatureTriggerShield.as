struct FLocomotionFeatureTriggerShieldAnimData
{
	UPROPERTY(Category = "TriggerShield")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "TriggerShield")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "TriggerShield")
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "TriggerShield")
	FHazePlaySequenceData Break;
}

class ULocomotionFeatureTriggerShield : UHazeLocomotionFeatureBase
{
	default Tag = n"TriggerShield";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTriggerShieldAnimData AnimData;
}
