struct FLocomotionFeatureSkippingStonesAnimData
{
	UPROPERTY(Category = "Skipping Stones")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "Skipping Stones")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Skipping Stones")
	FHazePlaySequenceData Aim;

	UPROPERTY(Category = "Skipping Stones")
	FHazePlaySequenceData Throw;

	UPROPERTY(Category = "Skipping Stones")
	FHazePlaySequenceData Exit;
};

class ULocomotionFeatureSkippingStones : UHazeLocomotionFeatureBase
{
	default Tag = n"SkippingStones";

	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSkippingStonesAnimData AnimData;
};