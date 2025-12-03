struct FLocomotionFeatureMeltdownBossFloatingAnimData
{
	UPROPERTY(Category = "MeltdownBossFloating")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "MeltdownBossFloating")
	FHazePlaySequenceData Start_Left;

	UPROPERTY(Category = "MeltdownBossFloating")
	FHazePlaySequenceData Move_Left;

	UPROPERTY(Category = "MeltdownBossFloating")
	FHazePlaySequenceData Stop_Left;

	UPROPERTY(Category = "MeltdownBossFloating")
	FHazePlaySequenceData Start_Right;

	UPROPERTY(Category = "MeltdownBossFloating")
	FHazePlaySequenceData Move_Right;

	UPROPERTY(Category = "MeltdownBossFloating")
	FHazePlaySequenceData Stop_Right;
}

class ULocomotionFeatureMeltdownBossFloating : UHazeLocomotionFeatureBase
{
	default Tag = n"MeltdownBossFloating";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMeltdownBossFloatingAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
