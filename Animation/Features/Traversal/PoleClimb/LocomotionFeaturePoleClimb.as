struct FLocomotionFeaturePoleClimbAnimData
{
	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData EnterFromGround;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData EnterFromAir;

	UPROPERTY(Category = "Enters")
	FHazePlaySequenceData EnterDownFromPerch;
	
	UPROPERTY(Category = "Blendspace")
	FHazePlayBlendSpaceData ClimbingBS;

	UPROPERTY(Category = "Blendspace")
	FHazePlayBlendSpaceData ClimbUpStartBS;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData ClimbUpStart;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData ClimbUpLoop;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData ClimbUpStop;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData ClimbUpStopLeft;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData SlideDownStart;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData SlideDownLoop;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData SlideDownStop;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData ClimbClockwise;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData ClimbCounterClockwise;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData Mantle;

	UPROPERTY(Category = "PoleClimb")
	FHazePlaySequenceData LetGo;

	UPROPERTY(Category = "JumpingOff")
	FHazePlaySequenceData JumpFwdLeft;

	UPROPERTY(Category = "JumpingOff")
	FHazePlaySequenceData JumpFwdRight;

	UPROPERTY(Category = "JumpingOff")
	FHazePlaySequenceData JumpBackLeft;

	UPROPERTY(Category = "JumpingOff")
	FHazePlaySequenceData JumpBackRight;

	UPROPERTY(Category = "JumpingOff")
	FHazePlaySequenceData JumpLeft;

	UPROPERTY(Category = "JumpingOff")
	FHazePlaySequenceData JumpRight;

	UPROPERTY(Category = "Dashing")
	FHazePlaySequenceData DashUpLeft;

	UPROPERTY(Category = "Dashing")
	FHazePlaySequenceData DashUpRight;
	
	UPROPERTY(Category = "Slipping")
	FHazePlaySequenceData SlippingStart;

	UPROPERTY(Category = "Slipping")
	FHazePlayBlendSpaceData SlippingBS;

	UPROPERTY(Category = "TurnAround180")
	FHazePlaySequenceData EnterTurnLeft180;

	UPROPERTY(Category = "TurnAround180")
	FHazePlaySequenceData EnterTurnRight180;

	UPROPERTY(Category = "TurnAround180")
	FHazePlaySequenceData TurnLeft180;

	UPROPERTY(Category = "TurnAround180")
	FHazePlaySequenceData TurnRight180;

	UPROPERTY(Category = "Lean")
	FHazePlaySequenceData LeanLeftStart;

	UPROPERTY(Category = "Lean")
	FHazePlaySequenceData LeanLeftMH;

	UPROPERTY(Category = "Lean")
	FHazePlaySequenceData LeanSwitchLeftToRight;

	UPROPERTY(Category = "Lean")
	FHazePlaySequenceData LeanRightStart;

	UPROPERTY(Category = "Lean")
	FHazePlaySequenceData LeanRightMH;

	UPROPERTY(Category = "Lean")
	FHazePlaySequenceData LeanSwitchRightToLeft;
}

class ULocomotionFeaturePoleClimb : UHazeLocomotionFeatureBase
{
	default Tag = n"PoleClimb";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePoleClimbAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
