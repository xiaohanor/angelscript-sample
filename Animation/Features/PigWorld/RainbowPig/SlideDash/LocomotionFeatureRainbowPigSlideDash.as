struct FLocomotionFeatureRainbowPigSlideDashAnimData
{
	UPROPERTY(Category = "RainbowPigSlideDash")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "RainbowPigSlideDash")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "RainbowPigSlideDash")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureRainbowPigSlideDash : UHazeLocomotionFeatureBase
{
	default Tag = n"SlideDash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRainbowPigSlideDashAnimData AnimData;
}
