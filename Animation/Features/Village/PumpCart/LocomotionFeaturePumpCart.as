struct FLocomotionFeaturePumpCartAnimData
{
	UPROPERTY(Category = "PumpCart")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "PumpCart")
	FHazePlaySequenceData UpMH;

	UPROPERTY(Category = "PumpCart")
	FHazePlaySequenceData UpToDown;

	UPROPERTY(Category = "PumpCart")
	FHazePlaySequenceData DownMH;

	UPROPERTY(Category = "PumpCart")
	FHazePlaySequenceData DownToUp;

	UPROPERTY(Category = "PumpCart")
	FHazePlaySequenceData MioFail;

	UPROPERTY(Category = "PumpCart")
	FHazePlaySequenceData ZoeFail;

	UPROPERTY(Category = "PumpCart")
	FHazePlaySequenceData UpExit;

	UPROPERTY(Category = "PumpCart")
	FHazePlaySequenceData DownExit;
}

class ULocomotionFeaturePumpCart : UHazeLocomotionFeatureBase
{
	default Tag = n"PumpCart";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePumpCartAnimData AnimData;
}
