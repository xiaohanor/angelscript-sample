struct FLocomotionFeatureStretchyPigStretchAnimData
{
	UPROPERTY(Category = "StretchyPigStretch")
	FHazePlaySequenceData StretchEnter;

	UPROPERTY(Category = "StretchyPigStretch")
	FHazePlaySequenceData StretchMH;

	UPROPERTY(Category = "StretchyPigStretch")
	FHazePlayBlendSpaceData Locomotion;

	UPROPERTY(Category = "StretchyPigStretch")
	FHazePlaySequenceData RunStop;

	UPROPERTY(Category = "StretchyPigStretch")
	FHazePlaySequenceData StretchExit;

	UPROPERTY(Category = "StretchyPigStretch")
	FHazePlayBlendSpaceData EnterFailBS;

}

class ULocomotionFeatureStretchyPigStretch : UHazeLocomotionFeatureBase
{
	default Tag = n"Stretched";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStretchyPigStretchAnimData AnimData;
}
