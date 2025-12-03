struct FLocomotionFeatureStrafeAnimData
{
	UPROPERTY(Category = "Strafe")
	FHazePlayBlendSpaceData StrafeBS;

	UPROPERTY(Category = "TurnInPlace|Left")
	FHazePlaySequenceData TurnInPlaceLeft22;

	UPROPERTY(Category = "TurnInPlace|Left")
	FHazePlaySequenceData TurnInPlaceLeft45;

	UPROPERTY(Category = "TurnInPlace|Left")
	FHazePlaySequenceData TurnInPlaceLeft90;

	UPROPERTY(Category = "TurnInPlace|Left")
	FHazePlaySequenceData TurnInPlaceLeft180;

	UPROPERTY(Category = "TurnInPlace|Right")
	FHazePlaySequenceData TurnInPlaceRight22;

	UPROPERTY(Category = "TurnInPlace|Right")
	FHazePlaySequenceData TurnInPlaceRight45;

	UPROPERTY(Category = "TurnInPlace|Right")
	FHazePlaySequenceData TurnInPlaceRight90;

	UPROPERTY(Category = "TurnInPlace|Right")
	FHazePlaySequenceData TurnInPlaceRight180;

	UPROPERTY(Category = "Fwd")
	FHazePlaySequenceData RunStartFwd;

	UPROPERTY(Category = "Fwd")
	FHazePlaySequenceData RunStopFwd;

	UPROPERTY(Category = "Walk|Fwd")
	FHazePlayBlendSpaceData ForwardWalkStartBS;

	UPROPERTY(Category = "Walk|Fwd")
	FHazePlayBlendSpaceData ForwardWalkLocomotionBS;

	UPROPERTY(Category = "Walk|Fwd")
	FHazePlayBlendSpaceData ForwardWalkStopBS;

	UPROPERTY(Category = "Walk|Bwd")
	FHazePlayBlendSpaceData BackwardWalkStartBS;

	UPROPERTY(Category = "Walk|Bwd")
	FHazePlayBlendSpaceData BackwardWalkLocomotionBS;

	UPROPERTY(Category = "Walk|Bwd")
	FHazePlayBlendSpaceData BackwardWalkStopBS;

	UPROPERTY(Category = "Walk|Left")
	FHazePlayBlendSpaceData LeftWalkStartBS;

	UPROPERTY(Category = "Walk|Left")
	FHazePlayBlendSpaceData LeftWalkLocomotionBS;
	
	UPROPERTY(Category = "Walk|Left")
	FHazePlayBlendSpaceData LeftWalkStopBS;

	UPROPERTY(Category = "Walk|Right")
	FHazePlayBlendSpaceData RightWalkStartBS;

	UPROPERTY(Category = "Walk|Right")
	FHazePlayBlendSpaceData RightWalkLocomotionBS;

	UPROPERTY(Category = "Walk|Right")
	FHazePlayBlendSpaceData RightWalkStopBS;

	UPROPERTY(Category = "Run|Fwd")
	FHazePlayBlendSpaceData ForwardRunStartBS;

	UPROPERTY(Category = "Run|Fwd")
	FHazePlayBlendSpaceData ForwardRunLocomotionBS;

	UPROPERTY(Category = "Run|Fwd")
	FHazePlayBlendSpaceData ForwardRunStopBS;

	UPROPERTY(Category = "Run|Bwd")
	FHazePlayBlendSpaceData BackwardRunStartBS;

	UPROPERTY(Category = "Run|Bwd")
	FHazePlayBlendSpaceData BackwardRunLocomotionBS;

	UPROPERTY(Category = "Run|Bwd")
	FHazePlayBlendSpaceData BackwardRunStopBS;

	UPROPERTY(Category = "Run|Left")
	FHazePlayBlendSpaceData LeftRunStartBS;

	UPROPERTY(Category = "Run|Left")
	FHazePlayBlendSpaceData LeftRunLocomotionBS;
	
	UPROPERTY(Category = "Run|Left")
	FHazePlayBlendSpaceData LeftRunStopBS;

	UPROPERTY(Category = "Run|Right")
	FHazePlayBlendSpaceData RightRunStartBS;

	UPROPERTY(Category = "Run|Right")
	FHazePlayBlendSpaceData RightRunLocomotionBS;

	UPROPERTY(Category = "Run|Right")
	FHazePlayBlendSpaceData RightRunStopBS;

}

class ULocomotionFeatureStrafe : UHazeLocomotionFeatureBase
{
	default Tag = n"StrafeFloor";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStrafeAnimData AnimData;
}

enum EHazeStrafeLocomotionAnimationType
{
	Fwd,
	Bwd,
	Left,
	Right,
};
