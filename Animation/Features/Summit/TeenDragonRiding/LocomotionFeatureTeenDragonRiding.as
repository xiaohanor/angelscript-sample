struct FLocomotionFeatureTeenDragonRidingAnimData
{
	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayBlendSpaceData LocomotionStart;
	
	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayBlendSpaceData Walk;

	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayBlendSpaceData Jog;

	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayBlendSpaceData LocomotionStop;

	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayBlendSpaceData SprintStart;
	
	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayBlendSpaceData Sprint;

	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayBlendSpaceData HoverEnter;

	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayBlendSpaceData HoverEnterNoBoost;
	
	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayBlendSpaceData Hover;
	
	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlaySequenceData GestureInterrupt;

	UPROPERTY(Category = "TeenDragonRiding")
	FHazePlayRndSequenceData Gestures;
}

class ULocomotionFeatureTeenDragonRiding : UHazeLocomotionFeatureBase
{
	default Tag = n"TeenDragonRiding";

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTeenDragonRidingAnimData AnimData;
}
