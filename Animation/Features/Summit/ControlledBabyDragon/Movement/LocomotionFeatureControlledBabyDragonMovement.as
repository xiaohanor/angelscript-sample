struct FLocomotionFeatureControlledBabyDragonMovementAnimData
{
	UPROPERTY(Category= "Mh")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "ControlledBabyDragonMovement")
	FHazePlayBlendSpaceData LocomotionStartBS;
	
	UPROPERTY(Category = "ControlledBabyDragonMovement")
	FHazePlayBlendSpaceData LocomotionBS;

	UPROPERTY(Category= "ControlledBabyDragonMovement")
	FHazePlaySequenceData Stop;

	UPROPERTY(Category= "ControlledBabyDragonMovement")
	FHazePlaySequenceData Start;

	UPROPERTY(Category= "ControlledBabyDragonMovement")
	FHazePlaySequenceData StartBack;

	UPROPERTY(Category= "Gestures")
	FHazePlayRndSequenceData Gestures;
}

class ULocomotionFeatureControlledBabyDragonMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Movement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureControlledBabyDragonMovementAnimData AnimData;

	UPROPERTY(Category= "Gestures|Settings")
	FVector2D GestureTime = FVector2D(3, 7);
}
