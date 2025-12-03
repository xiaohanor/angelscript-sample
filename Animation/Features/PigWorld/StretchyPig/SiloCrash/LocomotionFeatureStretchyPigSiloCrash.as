struct FLocomotionFeatureStretchyPigSiloCrashAnimData
{
	UPROPERTY(Category = "StretchyPigSiloCrash")
	FHazePlaySequenceData SiloCrash;
}

class ULocomotionFeatureStretchyPigSiloCrash : UHazeLocomotionFeatureBase
{
	default Tag = n"SiloCrash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStretchyPigSiloCrashAnimData AnimData;
}
