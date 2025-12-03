struct FLocomotionFeatureSnowMonkeyPerchAnimData
{
	UPROPERTY(Category = "Perch|MH")
	FHazePlaySequenceData MHLeft;

	UPROPERTY(Category = "Perch|MH")
	FHazePlaySequenceData MHRight;


	UPROPERTY(Category = "Perch|Turns")
	FHazePlayBlendSpaceData TurnLeft;

	UPROPERTY(Category = "Perch|Turns")
	FHazePlayBlendSpaceData TurnRight;

	UPROPERTY(Category = "Perch|Turns")
	FHazePlaySequenceData TurnLeftToRight;

	UPROPERTY(Category = "Perch|Turns")
	FHazePlaySequenceData TurnRightToLeft;


	UPROPERTY(Category = "Perch|Enter")
	FHazePlaySequenceData EnterLeft;

	UPROPERTY(Category = "Perch|Enter")
	FHazePlaySequenceData EnterRight;


	UPROPERTY(Category = "Perch|Land")
	FHazePlaySequenceData LandLeft;

	UPROPERTY(Category = "Perch|Land")
	FHazePlaySequenceData LandRight;


	UPROPERTY(Category = "Perch|Jump")
	FHazePlaySequenceData JumpStillLeft;

	UPROPERTY(Category = "Perch|Jump")
	FHazePlaySequenceData JumpStillRight;

	UPROPERTY(Category = "Perch|Jump")
	FHazePlaySequenceData JumpOffLeft;

	UPROPERTY(Category = "Perch|Jump")
	FHazePlaySequenceData JumpOffRight;



	UPROPERTY(Category = "Perch|Spline")
	FHazePlaySequenceData SplineMH;

	UPROPERTY(Category = "Perch|Spline")
	FHazePlaySequenceData SplineEnter;

	UPROPERTY(Category = "Perch|Spline")
	FHazePlaySequenceData SplineEnterMove;

	UPROPERTY(Category = "Perch|Spline")
	FHazePlayBlendSpaceData SplineMovement;

	UPROPERTY(Category = "Perch|Spline")
	FHazePlaySequenceData SplineStop;

	UPROPERTY(Category = "Perch|Spline")
	FHazePlaySequenceData SplineJumpStill;

	UPROPERTY(Category = "Perch|Spline")
	FHazePlaySequenceData SplineJumpMoving;


}

class ULocomotionFeatureSnowMonkeyPerch : UHazeLocomotionFeatureBase
{
	default Tag = n"Perch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyPerchAnimData AnimData;
}
