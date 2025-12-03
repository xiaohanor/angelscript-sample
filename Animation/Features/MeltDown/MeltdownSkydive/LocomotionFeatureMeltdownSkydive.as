struct FLocomotionFeatureMeltdownSkydiveAnimData
{
	UPROPERTY(Category = "MeltdownSkydive")
	FHazePlayBlendSpaceData MeltdownSkydiveBlendSpace;

	UPROPERTY(Category = "MeltdownSkydive")
	FHazePlaySequenceData MeltdownSkydiveDashLeft;

	UPROPERTY(Category = "MeltdownSkydive")
	FHazePlaySequenceData MeltdownSkydiveDashRight;

	UPROPERTY(Category = "MeltdownSkydive")
	FHazePlaySequenceData MeltdownSkydiveHitRight;

	UPROPERTY(Category = "MeltdownSkydive")
	FHazePlaySequenceData MeltdownSkydiveHitLeft;
}

class ULocomotionFeatureMeltdownSkydive : UHazeLocomotionFeatureBase
{
	default Tag = n"MeltdownSkydive";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureMeltdownSkydiveAnimData AnimData;
}
