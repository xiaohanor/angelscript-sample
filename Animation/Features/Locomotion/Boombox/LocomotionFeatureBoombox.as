struct FLocomotionFeatureBoomboxAnimData
{
UPROPERTY(Category = "Boombox")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "Boombox")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Boombox")
	FHazePlaySequenceData SpinClockwise;

	UPROPERTY(Category = "Boombox")
	FHazePlaySequenceData SpinAntiClockwise;

	UPROPERTY(Category = "Boombox")
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "Boombox")
	FHazePlaySequenceData ZoeExit;
}

class ULocomotionFeatureBoombox : UHazeLocomotionFeatureBase
{
	default Tag = n"Boombox";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBoomboxAnimData AnimData;
}
