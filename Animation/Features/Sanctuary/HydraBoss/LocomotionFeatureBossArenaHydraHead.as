struct FLocomotionFeatureBossArenaHydraHeadAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Mh;

}

class ULocomotionFeatureBossArenaHydraHead : UHazeLocomotionFeatureBase
{
	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBossArenaHydraHeadAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
