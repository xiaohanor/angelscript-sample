struct FLocomotionFeatureStretchyPigLandingAnimData
{
	UPROPERTY(Category = "StretchyPigLanding")
	FHazePlaySequenceData LandStill;

	UPROPERTY(Category = "StretchyPigLanding")
	FHazePlaySequenceData LandRun;
}

class ULocomotionFeatureStretchyPigLanding : UHazeLocomotionFeatureBase
{
	default Tag = n"Landing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStretchyPigLandingAnimData AnimData;
}
