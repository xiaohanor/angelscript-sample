struct FLocomotionFeatureCoughingAnimData
{
	UPROPERTY(Category = "Coughing")
	FHazePlaySequenceData LightCoughing;

	UPROPERTY(Category = "Coughing")
	FHazePlaySequenceData HeavyCoughing;
}

class ULocomotionFeatureCoughing : UHazeLocomotionFeatureBase
{
	default Tag = n"Coughing";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCoughingAnimData AnimData;
}
