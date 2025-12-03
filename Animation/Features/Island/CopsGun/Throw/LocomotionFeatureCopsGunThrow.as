struct FLocomotionFeatureCopsGunThrowAnimData
{
	UPROPERTY(Category = "CopsGunThrow")
	FHazePlaySequenceData Throw;
}

class ULocomotionFeatureCopsGunThrow : UHazeLocomotionFeatureBase
{
	default Tag = n"CopsGunThrow";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCopsGunThrowAnimData AnimData;
}
