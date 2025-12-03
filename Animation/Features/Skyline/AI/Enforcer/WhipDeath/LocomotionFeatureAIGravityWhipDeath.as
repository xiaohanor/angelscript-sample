struct FLocomotionFeatureAIGravityWhipDeathAnimData
{
	UPROPERTY(Category = "Death")
	FHazePlaySequenceData Death;

	UPROPERTY(Category = "Death")
	FHazePlayRndSequenceData RandomDeath;

	UPROPERTY(Category = "Death")
	FHazePlayBlendSpaceData GravityWhipDeath;

	UPROPERTY(Category = "Death")
	FHazePlayBlendSpaceData GravityWhipMoveDirection;

	UPROPERTY(Category = "Death")
	FHazePlayBlendSpaceData GravityWhipDeathRecovery;

	UPROPERTY(Category = "AirDeath")
	FHazePlaySequenceData AirDeath;
}

class ULocomotionFeatureAIGravityWhipDeath : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::GravityWhipDeath;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAIGravityWhipDeathAnimData AnimData;
}
