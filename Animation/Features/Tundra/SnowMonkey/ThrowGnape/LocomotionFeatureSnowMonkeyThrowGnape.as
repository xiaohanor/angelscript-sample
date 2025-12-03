struct FLocomotionFeatureSnowMonkeyThrowGnapeAnimData
{
	UPROPERTY(Category = "SnowMonkeyThrowGnape")
	FHazePlaySequenceData Grab;

	UPROPERTY(Category = "SnowMonkeyThrowGnape")
	FHazePlayBlendSpaceData Movement;

	UPROPERTY(Category = "SnowMonkeyThrowGnape")
	FHazePlaySequenceData Throw;
}

namespace SnowMonkeyGnapeFeatureTags
{
	const FName SnowMonkeyThrowGnapeTag = n"SnowMonkeyThrowGnape";
}

class ULocomotionFeatureSnowMonkeyThrowGnape : UHazeLocomotionFeatureBase
{
	default Tag = SnowMonkeyGnapeFeatureTags::SnowMonkeyThrowGnapeTag;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyThrowGnapeAnimData AnimData;
}
