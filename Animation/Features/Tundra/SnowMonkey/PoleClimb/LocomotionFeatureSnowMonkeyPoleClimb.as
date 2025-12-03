struct FLocomotionFeatureSnowMonkeyPoleClimbAnimData
{
	UPROPERTY(Category = "Enter")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "Enter")
	FHazePlaySequenceData EnterLeft180;

	UPROPERTY(Category = "Enter")
	FHazePlaySequenceData EnterRight180;

	UPROPERTY(Category = "Enter")
	FHazePlaySequenceData EnterFromPerch;


	UPROPERTY(Category = "MH")
	FHazePlaySequenceData LeftHandMH;

	UPROPERTY(Category = "MH")
	FHazePlaySequenceData RightHandMH;


	UPROPERTY(Category = "Turn")
	FHazePlayBlendSpaceData TurnLeftHandClockwise;

	UPROPERTY(Category = "Turn")
	FHazePlayBlendSpaceData TurnRightHandCounterClockwise;

	UPROPERTY(Category = "Turn")
	FHazePlaySequenceData TurnLeft180;

	UPROPERTY(Category = "Turn")
	FHazePlaySequenceData TurnRight180;


	UPROPERTY(Category = "ClimbUp")
	FHazePlaySequenceData LeftHandClimbUp;

	UPROPERTY(Category = "ClimbUp")
	FHazePlaySequenceData RightHandClimbUp;


	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData LeftHandDash;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData LeftHandDashToClimb;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData RightHandDash;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData RightHandDashToClimb;


	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpBack;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpFwdLeft;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpFwdRight;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpLeft;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData JumpRight;


	UPROPERTY(Category = "Cancel")
	FHazePlaySequenceData Cancel;


	UPROPERTY(Category = "SlideDown")
	FHazePlaySequenceData LeftHandSlideDown;

	UPROPERTY(Category = "SlideDown")
	FHazePlaySequenceData RightHandSlideDown;


	UPROPERTY(Category = "ToPerch")
	FHazePlaySequenceData ExitToPerch;


	UPROPERTY(Category = "SlippingDown")
	FHazePlaySequenceData SlippingDown;

}

class ULocomotionFeatureSnowMonkeyPoleClimb : UHazeLocomotionFeatureBase
{
	default Tag = n"PoleClimb";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyPoleClimbAnimData AnimData;
}
