struct FLocomotionFeatureIslandSkydiveAnimData
{
	UPROPERTY(Category = "IslandSkydive")
	FHazePlayBlendSpaceData IslandSkydiveBlendSpace;

	UPROPERTY(Category = "IslandSkydive")
	FHazePlaySequenceData IslandSkydiveDashLeft;

	UPROPERTY(Category = "IslandSkydive")
	FHazePlaySequenceData IslandSkydiveDashRight;

	UPROPERTY(Category = "IslandSkydive")
	FHazePlaySequenceData IslandSkydiveHitRight;

	UPROPERTY(Category = "IslandSkydive")
	FHazePlaySequenceData IslandSkydiveHitLeft;

	UPROPERTY(Category = "IslandSkydive")
	FHazePlayBlendSpaceData IslandSlowSkydiveBlendSpace;

	UPROPERTY(Category = "IslandSkydive")
	FHazePlaySequenceData IslandSlowSkydiveDashRight;

	UPROPERTY(Category = "IslandSkydive")
	FHazePlaySequenceData IslandSlowSkydiveDashLeft;



}

class ULocomotionFeatureIslandSkydive : UHazeLocomotionFeatureBase
{
	default Tag = n"IslandSkydive";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureIslandSkydiveAnimData AnimData;
}
