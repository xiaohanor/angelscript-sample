struct FLocomotionFeatureHoverboardAirMovementAnimData
{
	UPROPERTY(Category = "HoverboardAirMovement")
	FHazePlayBlendSpaceData Falling;

	UPROPERTY(Category = "HoverboardAirMovement")
	FHazePlayBlendSpaceData Banking;
}

class ULocomotionFeatureHoverboardAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"HoverboardAirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardAirMovementAnimData AnimData;

	UPROPERTY(Category = "Tricks")
	UBattlefieldHoverboardTrickList TrickListX;

	UPROPERTY(Category = "Tricks")
	UBattlefieldHoverboardTrickList TrickListY;

	UPROPERTY(Category = "Tricks")
	UBattlefieldHoverboardTrickList TrickListB;
}
