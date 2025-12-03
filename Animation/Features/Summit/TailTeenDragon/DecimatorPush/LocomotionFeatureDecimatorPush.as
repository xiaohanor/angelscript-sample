struct FLocomotionFeatureDecimatorPushAnimData
{
	UPROPERTY(Category = "DecimatorPush")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "DecimatorPush")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "DecimatorPush")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "DecimatorPush")
	FHazePlaySequenceData Push;

	UPROPERTY(Category = "DecimatorPush")
	FHazePlaySequenceData Stop;
}

class ULocomotionFeatureDecimatorPush : UHazeLocomotionFeatureBase
{
	default Tag = n"DecimatorPush";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDecimatorPushAnimData AnimData;

	// Settings

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;

	// How long it'll take between each gesture (in seconds). A random value will be picked (X: Min, Y: Max)
	UPROPERTY(Category= "Settings")
	FVector2D GestureTimeRange = FVector2D(3, 7);
}
