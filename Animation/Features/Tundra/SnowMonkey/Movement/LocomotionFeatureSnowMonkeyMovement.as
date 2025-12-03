struct FLocomotionFeatureSnowMonkeyMovementAnimData
{
	UPROPERTY(Category = "MH")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "MH")
	FHazePlayRndSequenceData Gestures;

	UPROPERTY(BlueprintReadOnly, Category = "AFKIdle")
    FHazePlaySequenceData AFKIdleEnter;

	UPROPERTY(BlueprintReadOnly, Category = "AFKIdle")
    FHazePlaySequenceData AFKIdleMH;

	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData LocomotionStart;

	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData Locomotion;
	
	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData Walk;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData Run;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData WalkTurn180;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData RunTurnLeft180;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData RunTurnRight180;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData LocomotionWalkStop;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData LocomotionRunStop;

	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
}

class ULocomotionFeatureSnowMonkeyMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"Movement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyMovementAnimData AnimData;

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;

	UPROPERTY(Category = "Timers")
	FHazeRange GestureTimeRange;
	default GestureTimeRange.Min = 1;
	default GestureTimeRange.Max = 20;


	UPROPERTY(Category = "Timers")
	FHazeRange AFKIdleTimeRange;
	default AFKIdleTimeRange.Min = 60;
	default AFKIdleTimeRange.Max = 80;

}
