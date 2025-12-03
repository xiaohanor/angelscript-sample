struct FLocomotionFeatureSnowMonkeyLandingAnimData
{
	UPROPERTY(Category = "SnowMonkeyLanding")
	FHazePlaySequenceData ExitToMH;

	UPROPERTY(Category = "SnowMonkeyLanding")
	FHazePlaySequenceData ExitToMovement;
}

class ULocomotionFeatureSnowMonkeyLanding : UHazeLocomotionFeatureBase
{
	default Tag = n"Landing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyLandingAnimData AnimData;
}
