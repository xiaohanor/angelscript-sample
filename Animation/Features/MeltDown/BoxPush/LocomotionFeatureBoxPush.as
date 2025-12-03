struct FLocomotionFeatureBoxPushAnimData
{
	UPROPERTY(Category = "BoxPush")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "BoxPush")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "BoxPush")
	FHazePlayBlendSpaceData StartBS;
	
	UPROPERTY(Category = "BoxPush")
	FHazePlayBlendSpaceData MoveBS;

	UPROPERTY(Category = "BoxPush")
	FHazePlayBlendSpaceData StopBS;

	UPROPERTY(Category = "BoxPush")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureBoxPush : UHazeLocomotionFeatureBase
{
	default Tag = n"BoxPush";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBoxPushAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
