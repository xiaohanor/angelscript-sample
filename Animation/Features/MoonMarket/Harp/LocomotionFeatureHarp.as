struct FLocomotionFeatureHarpAnimData
{
	UPROPERTY(Category = "Harp")
	FHazePlaySequenceData MH;
	UPROPERTY(Category = "Harp")
	FHazePlaySequenceData Intro;
	UPROPERTY(Category = "Harp")
	FHazePlaySequenceData Ready;

	UPROPERTY(Category = "Harp")
	FHazePlayRndSequenceData Success;
	UPROPERTY(Category = "Harp")
	FHazePlayRndSequenceData Fail;

	UPROPERTY(Category = "Harp")
	FHazePlaySequenceData Exit;

}

class ULocomotionFeatureHarp : UHazeLocomotionFeatureBase
{
	default Tag = n"Harp";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHarpAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
