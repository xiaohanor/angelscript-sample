struct FLocomotionFeatureSimpleDragonMovementAnimData
{
	UPROPERTY(Category = "SimpleMovement")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData LocomotionStart;
	
	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData Walk;

	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData Jog;

	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData LocomotionStop;

	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData SprintStart;
	
	UPROPERTY(Category = "SimpleMovement")
	FHazePlayBlendSpaceData Sprint;

	//Commenting these lines out since they currently A: Are not blendspaces, and B: have no assigned animations, and thus create blends to T-pose in the ABP - Felix

	// UPROPERTY(Category = "SimpleMovement") 
	// FHazePlaySequenceData SprintLeft;

	// UPROPERTY(Category = "SimpleMovement")
	// FHazePlaySequenceData SprintRight;

	UPROPERTY(Category = "Gestures")
	FHazePlaySequenceData GestureInterrupt;

	UPROPERTY(Category = "Gestures")
	FHazePlayRndSequenceData Gestures;


}

class ULocomotionFeatureSimpleDragonMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Movement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSimpleDragonMovementAnimData AnimData;

	// Settings

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;

	// How long it'll take between each gesture (in seconds). A random value will be picked (X: Min, Y: Max)
	UPROPERTY(Category= "Settings")
	FVector2D GestureTimeRange = FVector2D(3, 7);
}
