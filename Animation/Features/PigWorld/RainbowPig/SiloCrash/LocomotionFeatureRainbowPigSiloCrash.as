struct FLocomotionFeatureRainbowPigSiloCrashAnimData
{
	UPROPERTY(Category = "RainbowPigSiloCrash")
	FHazePlaySequenceData SiloCrash;
}

class ULocomotionFeatureRainbowPigSiloCrash : UHazeLocomotionFeatureBase
{
	default Tag = n"SiloCrash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRainbowPigSiloCrashAnimData AnimData;
}
