struct FLocomotionFeatureLifeAndDeathForceAnimData
{
	UPROPERTY(Category = "LifeAndDeathForce")
	FHazePlaySequenceData LifeAndDeathForceStart;

	UPROPERTY(Category = "LifeAndDeathForce")
	FHazePlaySequenceData LifeAndDeathForceLoop;

		UPROPERTY(Category = "LifeAndDeathForce")
	FHazePlaySequenceData LifeAndDeathForceSettle;
}

class ULocomotionFeatureLifeAndDeathForce : UHazeLocomotionFeatureBase
{
	default Tag = n"LifeAndDeathForce";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLifeAndDeathForceAnimData AnimData;
}
