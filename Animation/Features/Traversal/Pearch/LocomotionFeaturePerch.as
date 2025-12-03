struct FLocomotionFeaturePerchAnimData
{

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
    FHazePlayBlendSpaceData BSEnterForwardLFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
    FHazePlayBlendSpaceData BSEnterForwardRFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
    FHazePlaySequenceData EnterForwardLFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
    FHazePlaySequenceData EnterForwardRFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
    FHazePlaySequenceData EnterLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
    FHazePlaySequenceData EnterRight;

	UPROPERTY(BlueprintReadOnly, Category = "Enter")
    FHazePlaySequenceData EnterBackward;

	UPROPERTY(BlueprintReadOnly, Category = "Enter|Up")
    FHazePlaySequenceData EnterUpLFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Landing")
	FHazePlayBlendSpaceData BSFallingToLandingLFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Landing")
	FHazePlayBlendSpaceData BSFallingToLandingRFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Landing")
	FHazePlayBlendSpaceData BSPerchLandingLeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Landing")
	FHazePlayBlendSpaceData BSPerchLandingRightFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Landing")
    FHazePlaySequenceData PerchLanding;

	UPROPERTY(BlueprintReadOnly, Category = "Landing")
    FHazePlaySequenceData PerchLandingRightFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Landing")
    FHazePlaySequenceData PerchLandingLeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Landing")
    FHazePlaySequenceData PerchLandingShort;

	UPROPERTY(BlueprintReadOnly, Category = "Landing|Up")
    FHazePlaySequenceData PerchLandingUpLFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Landing|Spline")
	FHazePlaySequenceData SplineLanding;

	UPROPERTY(BlueprintReadOnly, Category = "Landing|Spline")
	FHazePlaySequenceData SplineLandingShort;

	UPROPERTY(BlueprintReadOnly, Category = "Landing|Spline")
	FHazePlayBlendSpaceData BSSplineLandingLeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Landing|Spline")
	FHazePlayBlendSpaceData BSSplineLandingRightFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Perching")
	FHazePlaySequenceData AlertMh;

	UPROPERTY(BlueprintReadOnly, Category = "Perching")
	FHazePlayBlendSpaceData BSAlertMh;

	UPROPERTY(BlueprintReadOnly, Category = "Perching")
	FHazePlayBlendSpaceData BSRelaxMh;

	UPROPERTY(BlueprintReadOnly, Category = "Perching")
	FHazePlaySequenceData ReadyMh;

	UPROPERTY(BlueprintReadOnly, Category = "Perching")
	FHazePlayBlendSpaceData BSReadyMh;
	
	UPROPERTY(BlueprintReadOnly, Category = "Perching")
	FHazePlaySequenceData MhToRelax;

	UPROPERTY(BlueprintReadOnly, Category = "Perching")
	FHazePlaySequenceData RelaxToMh;

	UPROPERTY(BlueprintReadOnly, Category = "Perching|Spline")
	FHazePlayBlendSpaceData BSSplineMove;

	UPROPERTY(BlueprintReadOnly, Category = "Perching|Spline")
	FHazePlayBlendSpaceData BSSplineStart;

	UPROPERTY(BlueprintReadOnly, Category = "Perching|Spline")
	FHazePlayBlendSpaceData BSSplineStop;

	UPROPERTY(BlueprintReadOnly, Category = "Perching|Spline")
	FHazePlayBlendSpaceData BSSplineDash;

	UPROPERTY(BlueprintReadOnly, Category = "Perching|Spline")
	FHazePlayBlendSpaceData AdditiveLeanBS;

	UPROPERTY(BlueprintReadOnly, Category = "Jumping")
    FHazePlaySequenceData SpringJump;

	UPROPERTY(BlueprintReadOnly, Category = "Jumping")
    FHazePlaySequenceData SpringJumpStill;

	UPROPERTY(BlueprintReadOnly, Category = "Jumping")
    FHazePlaySequenceData SpringJumpRFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Jumping")
    FHazePlaySequenceData SpringJumpLFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Jumping")
    FHazePlaySequenceData SpringJumpFall;

	UPROPERTY(BlueprintReadOnly, Category = "Dashing")
    FHazePlaySequenceData SpringDash;
	
	UPROPERTY(BlueprintReadOnly, Category = "Exit")
    FHazePlayBlendSpaceData BSPerchExit;

	UPROPERTY(BlueprintReadOnly, Category = "Exit")
    FHazePlaySequenceData PerchExitToJog;

	UPROPERTY(BlueprintReadOnly, Category = "Exit")
    FHazePlaySequenceData PerchExitToMh;

	UPROPERTY(BlueprintReadOnly, Category = "Sidescroller")
    FHazePlaySequenceData PerchTurnLeft180;

	UPROPERTY(BlueprintReadOnly, Category = "Sidescroller")
    FHazePlaySequenceData PerchTurnRight180;

	UPROPERTY(Category = "Unbalanced")	
    FHazePlayBlendSpaceData UnbalancedBS;

}

class ULocomotionFeaturePerch : UHazeLocomotionFeatureBase
{
	default Tag = n"Perch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePerchAnimData AnimData;
}
