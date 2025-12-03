struct FLocomotionFeatureAcidTeenSpeedRingAnimData
{
	UPROPERTY(Category = "AcidTeenSpeedRing")
	FHazePlaySequenceData SpeedRingLeft;

	UPROPERTY(Category = "AcidTeenSpeedRing")
	FHazePlaySequenceData SpeedRingRight;
}

class ULocomotionFeatureAcidTeenSpeedRing : UHazeLocomotionFeatureBase
{
	default Tag = n"AcidTeenSpeedRing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAcidTeenSpeedRingAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
