struct FLocomotionFeatureSnowMonkeyThrowOtherPlayerAnimData
{
	UPROPERTY(Category = "SnowMonkeyThrowOtherPlayer")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "SnowMonkeyThrowOtherPlayer")
	FHazePlaySequenceData Launch;
}

class ULocomotionFeatureSnowMonkeyThrowOtherPlayer : UHazeLocomotionFeatureBase
{
	default Tag = n"SnowMonkeyThrowOtherPlayer";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyThrowOtherPlayerAnimData AnimData;
}
