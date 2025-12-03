struct FLocomotionFeatureHoverboardLandingAnimData
{
	UPROPERTY(Category = "HoverboardLanding")
	FHazePlaySequenceData Landing;

	UPROPERTY(Category = "HoverboardLanding")
	FHazePlaySequenceData LandingLight;

	UPROPERTY(Category = "HoverboardLanding")
	FHazePlaySequenceData LandingHeavy;

	UPROPERTY(Category = "HoverboardLanding")
	FHazePlaySequenceData LandingBehind;

	UPROPERTY(Category = "HoverboardLanding")
	FHazePlaySequenceData LandingBehindTurnRight;

	UPROPERTY(Category = "Hoverboard")
	FHazePlayBlendSpaceData Banking;

	UPROPERTY(Category = "Hoverboard")
	FHazePlayBlendSpaceData BankingFwdBack;

	UPROPERTY(Category = "HoverboardLanding")
	FHazePlaySequenceData Fail;
}

class ULocomotionFeatureHoverboardLanding : UHazeLocomotionFeatureBase
{
	default Tag = n"HoverboardLanding";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardLandingAnimData AnimData;
}
