struct FLocomotionFeatureSpiritFishAnimData
{
	UPROPERTY(Category = "SpiritFish")
	FHazePlaySequenceData Jump;
}

class ULocomotionFeatureSpiritFish : UHazeLocomotionFeatureBase
{
	default Tag = n"SpiritFish";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSpiritFishAnimData AnimData;

	// How much of the animation do we need to play before we exit into movement if player has stick input
	UPROPERTY(Category = "SpiritFish")
	float FactionBeforeExit = 0.6;
}
