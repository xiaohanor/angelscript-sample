struct FLocomotionFeatureSnowMonkeyHitReactionsAnimData
{
	UPROPERTY(Category = "HitReactions|Back")
	FHazePlaySequenceData BackSmall;

	UPROPERTY(Category = "HitReactions|Back")
	FHazePlaySequenceData BackBig;

	UPROPERTY(Category = "HitReactions|Fwd")
	FHazePlaySequenceData FwdSmall;

	UPROPERTY(Category = "HitReactions|Fwd")
	FHazePlaySequenceData FwdBig;

	UPROPERTY(Category = "HitReactions|Left")
	FHazePlaySequenceData LeftSmall;

	UPROPERTY(Category = "HitReactions|Left")
	FHazePlaySequenceData LeftBig;

	UPROPERTY(Category = "HitReactions|Right")
	FHazePlaySequenceData RightSmall;

	UPROPERTY(Category = "HitReactions|Right")
	FHazePlaySequenceData RightBig;
}

class ULocomotionFeatureSnowMonkeyHitReactions : UHazeLocomotionFeatureBase
{
	default Tag = n"HitReaction_Addative";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyHitReactionsAnimData AnimData;
}
