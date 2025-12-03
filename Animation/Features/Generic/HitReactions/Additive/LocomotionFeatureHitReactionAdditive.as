struct FLocomotionFeatureHitReaction_AdditiveAnimData
{
	UPROPERTY(Category = "HitReaction_Additive")
	FHazePlaySequenceData Backward;

	UPROPERTY(Category = "HitReaction_Additive")
	FHazePlaySequenceData BigBackward;

	UPROPERTY(Category = "HitReaction_Additive")
	FHazePlaySequenceData Forward;

	UPROPERTY(Category = "HitReaction_Additive")
	FHazePlaySequenceData BigForward;

	UPROPERTY(Category = "HitReaction_Additive")
	FHazePlaySequenceData Left;

	UPROPERTY(Category = "HitReaction_Additive")
	FHazePlaySequenceData BigLeft;

	UPROPERTY(Category = "HitReaction_Additive")
	FHazePlaySequenceData Right;

	UPROPERTY(Category = "HitReaction_Additive")
	FHazePlaySequenceData BigRight;
}

class ULocomotionFeatureHitReaction_Additive : UHazeLocomotionFeatureBase
{
	default Tag = n"HitReaction_Addative";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHitReaction_AdditiveAnimData AnimData;
}
