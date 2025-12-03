struct FLocomotionFeatureBackpackDragonZiplineAnimData
{
	UPROPERTY(Category = "BackpackDragonZipline")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "BackpackDragonZipline")
	FHazePlaySequenceData EnterInAir;

	UPROPERTY(Category = "BackpackDragonZipline")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "BackpackDragonZipline")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureBackpackDragonZipline : UHazeLocomotionFeatureBase
{
	default Tag = n"BackpackDragonZipline";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBackpackDragonZiplineAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
