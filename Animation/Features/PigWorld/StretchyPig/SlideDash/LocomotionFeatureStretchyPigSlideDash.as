struct FLocomotionFeatureStretchyPigSlideDashAnimData
{
	UPROPERTY(Category = "StretchyPigSlideDash")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "StretchyPigSlideDash")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "StretchyPigSlideDash")
	FHazePlaySequenceData Exit;

}

class ULocomotionFeatureStretchyPigSlideDash : UHazeLocomotionFeatureBase
{
	default Tag = n"SlideDash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStretchyPigSlideDashAnimData AnimData;
}
