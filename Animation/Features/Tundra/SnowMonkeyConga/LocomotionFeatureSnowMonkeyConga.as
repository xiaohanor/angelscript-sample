struct FLocomotionFeatureSnowMonkeyCongaAnimData
{
	UPROPERTY(Category = "SnowMonkeyConga")
	FHazePlaySequenceData Dance;

	UPROPERTY(Category = "SnowMonkeyConga")
	FHazePlaySequenceData Stumble;

	UPROPERTY(Category = "SnowMonkeyConga")
	FHazePlaySequenceData LoseMonkeys;

	UPROPERTY(Category = "SnowMonkeyConga")
	FHazePlaySequenceData Shame;

	
}

class ULocomotionFeatureSnowMonkeyConga : UHazeLocomotionFeatureBase
{
	default Tag = n"CongaMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyCongaAnimData AnimData;
}
