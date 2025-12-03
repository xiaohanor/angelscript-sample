struct FLocomotionFeatureStumbleAnimData
{
	UPROPERTY(Category = "Stumble")
	FHazePlaySequenceData Forward;

	UPROPERTY(Category = "Stumble")
	FHazePlaySequenceData Left;

	UPROPERTY(Category = "Stumble")
	FHazePlaySequenceData Right;

	UPROPERTY(Category = "Stumble")
	FHazePlaySequenceData Back;

	UPROPERTY(Category = "Air Stumble")
	FHazePlaySequenceData AirForward;

	UPROPERTY(Category = "Air Stumble")
	FHazePlaySequenceData AirLeft;

	UPROPERTY(Category = "Air Stumble")
	FHazePlaySequenceData AirRight;

	UPROPERTY(Category = "Air Stumble")
	FHazePlaySequenceData AirBack;
}

class ULocomotionFeatureStumble : UHazeLocomotionFeatureBase
{
	default Tag = n"Stumble";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStumbleAnimData AnimData;
}
