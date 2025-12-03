struct FLocomotionFeatureSlamAnimData
{
	UPROPERTY(Category = "Slam")
	FHazePlaySequenceData Start;
	
	UPROPERTY(Category = "Slam")
	FHazePlaySequenceData LeftSlam;

	UPROPERTY(Category = "Slam")
	FHazePlaySequenceData RightSlam;

	UPROPERTY(Category = "Slam")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureSlam : UHazeLocomotionFeatureBase
{
	default Tag = n"Slam";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSlamAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
