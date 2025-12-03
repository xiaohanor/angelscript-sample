struct FLocomotionFeatureHoverboardTricksAnimData
{
	UPROPERTY(Category = "HoverboardTricks")
	FHazePlayRndSequenceData TrickFwd;

	UPROPERTY(Category = "HoverboardTricks")
	FHazePlayRndSequenceData TrickSkydive;

	UPROPERTY(Category = "HoverboardJumping")
	FHazePlayBlendSpaceData JumpBanking;
}

class ULocomotionFeatureHoverboardTricks : UHazeLocomotionFeatureBase
{
	default Tag = n"HoverboardTricks";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardTricksAnimData AnimData;
}
