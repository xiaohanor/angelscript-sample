struct FLocomotionFeatureRainbowPigFartAnimData
{
	UPROPERTY(Category = "RainbowPigFart")
	FHazePlaySequenceData StartFart;

	UPROPERTY(Category = "RainbowPigFart")
	FHazePlaySequenceData FartMH;
}

class ULocomotionFeatureRainbowPigFart : UHazeLocomotionFeatureBase
{
	default Tag = n"Fart";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRainbowPigFartAnimData AnimData;
}
