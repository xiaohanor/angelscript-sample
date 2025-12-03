struct FLocomotionFeatureBotHangingAnimData
{
	UPROPERTY(Category = "BotHanging")
	FHazePlayBlendSpaceData BotHanging;

	UPROPERTY(Category = "BotHanging")
	FHazePlayBlendSpaceData VerticalAdditive;
}

class ULocomotionFeatureBotHanging : UHazeLocomotionFeatureBase
{
	default Tag = n"BotHanging";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBotHangingAnimData AnimData;
}
