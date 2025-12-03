struct FLocomotionFeatureControlledBabyDragonPushPullAnimData
{
	UPROPERTY(Category = "PushPull")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "PushPull")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "PushPull")
	FHazePlaySequenceData Pull;

	UPROPERTY(Category = "PushPull")
	FHazePlaySequenceData Exit;
	
	UPROPERTY(Category = "PushPull")
	FHazePlayBlendSpaceData PushPullBS;
}

class ULocomotionFeatureControlledBabyDragonPushPull : UHazeLocomotionFeatureBase
{
	default Tag = n"Pull";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureControlledBabyDragonPushPullAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
