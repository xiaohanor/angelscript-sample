struct FLocomotionFeatureWaterCannonAnimData
{
	UPROPERTY(Category = "WaterCannon")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "WaterCannon")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "WaterCannon")
	FHazePlaySequenceData Shoot;

}

class ULocomotionFeatureWaterCannon : UHazeLocomotionFeatureBase
{
	default Tag = n"WaterCannon";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWaterCannonAnimData AnimData;
}
