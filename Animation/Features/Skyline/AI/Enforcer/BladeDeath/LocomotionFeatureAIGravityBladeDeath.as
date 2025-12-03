struct FLocomotionFeatureAIGravityBladeDeathAnimData
{
	UPROPERTY(Category = "Death")
	FHazePlaySequenceData Death;

	UPROPERTY(Category = "Death")
	FHazePlayRndSequenceData RandomDeath;

	UPROPERTY(Category = "Death")
	FHazePlayBlendSpaceData GravityBladeDeath;

	UPROPERTY(Category = "Death")
	FHazePlayBlendSpaceData GravityBladeMoveDirection;

	UPROPERTY(Category = "Death")
	FHazePlayBlendSpaceData GravityBladeDeathRecovery;

	UPROPERTY(Category = "AirDeath")
	FHazePlaySequenceData AirDeath;
}

class ULocomotionFeatureAIGravityBladeDeath : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::GravityBladeHitReactionDeath;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAIGravityBladeDeathAnimData AnimData;
}
