struct FLocomotionFeatureSimpleMovementAnimData
{
	UPROPERTY(Category = "SimpleMovement")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData LocomotionStart;
	
	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData Locomotion;

	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData LocomotionStop;

	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData Sprint;

	UPROPERTY(Category = "Gestures")
	FHazePlayRndSequenceData Gestures;

	UPROPERTY(Category = "SimpleMovement")
	FHazePlaySequenceData Turn;

}

class ULocomotionFeatureSimpleMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Movement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSimpleMovementAnimData AnimData;

	// Settings

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;

	// How long it'll take between each gesture (in seconds). A random value will be picked (X: Min, Y: Max)
	UPROPERTY(Category= "Settings")
	FVector2D GestureTimeRange = FVector2D(3, 7);
}
