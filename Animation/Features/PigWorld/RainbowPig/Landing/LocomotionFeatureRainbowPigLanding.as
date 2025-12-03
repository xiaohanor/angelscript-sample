struct FLocomotionFeatureRainbowPigLandingAnimData
{
	UPROPERTY(Category = "RainbowPigLanding")
	FHazePlaySequenceData LandStill;

	UPROPERTY(Category = "RainbowPigLanding")
	FHazePlaySequenceData LandRun;
}

class ULocomotionFeatureRainbowPigLanding : UHazeLocomotionFeatureBase
{
	default Tag = n"Landing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRainbowPigLandingAnimData AnimData;
}
