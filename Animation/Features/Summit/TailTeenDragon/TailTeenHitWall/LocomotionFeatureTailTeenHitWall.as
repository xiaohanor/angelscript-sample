struct FLocomotionFeatureTailTeenHitWallAnimData
{
	UPROPERTY(Category = "TailTeenHitWall")
	FHazePlaySequenceData HitWall;
}

class ULocomotionFeatureTailTeenHitWall : UHazeLocomotionFeatureBase
{
	default Tag = n"TailTeenHitWall";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTailTeenHitWallAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
