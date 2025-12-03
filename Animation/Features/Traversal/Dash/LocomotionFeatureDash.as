struct FLocomotionFeatureDashAnimData
{
	
	UPROPERTY(Category = "StepDash|Forward")
	FHazePlaySequenceData StepDashFwdLeftFoot;

	UPROPERTY(Category = "StepDash|Forward")
	FHazePlaySequenceData StepDashFwd;
	
	UPROPERTY(Category = "StepDash|Forward")
	FHazePlaySequenceData FwdToMhLeftFoot;

	UPROPERTY(Category = "StepDash|Forward")
	FHazePlaySequenceData FwdToMh;

	UPROPERTY(Category = "StepDash|Forward")
	FHazePlaySequenceData FwdToRunLeftFoot;

	UPROPERTY(Category = "StepDash|Forward")
	FHazePlaySequenceData FwdToRun;
	
	UPROPERTY(Category = "StepDash|Forward")
	FHazePlayBlendSpaceData FwdToMovementLeftFoot;

	UPROPERTY(Category = "StepDash|Forward")
	FHazePlayBlendSpaceData FwdToMovement;

	UPROPERTY(Category = "StepDash|Forward")
	FHazePlaySequenceData FwdToSprintLeftFoot;

	UPROPERTY(Category = "StepDash|Forward")
	FHazePlaySequenceData FwdToSprint;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData StepDashBwd;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData BwdToMh;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData BwdToRun;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData StepDashLeft;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData LeftToMh;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData LeftToRunLeft;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData StepDashRight;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData RightToMh;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData RightToRunRight;

	UPROPERTY(BlueprintReadOnly, Category = "Dash")
    FHazePlaySequenceData DashLeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "Dash")
    FHazePlaySequenceData Dash;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit")
    FHazePlaySequenceData DashToMhLeftFoot;

    UPROPERTY(BlueprintReadOnly, Category = "DashExit")
    FHazePlaySequenceData DashToMh;
	
	UPROPERTY(BlueprintReadOnly, Category = "DashExit")
    FHazePlayBlendSpaceData DashToMovementLeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit")
    FHazePlayBlendSpaceData DashToMovement;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit|Sprint")
    FHazePlaySequenceData DashToSprint;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit|Sprint")
    FHazePlaySequenceData SprintCancel;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit")
    FHazePlaySequenceData DashToFallingLeftFoot;
	
	UPROPERTY(BlueprintReadOnly, Category = "DashExit")
    FHazePlaySequenceData DashToFalling;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit")
    FHazePlaySequenceData DashToSlideLeftFoot;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit")
    FHazePlaySequenceData DashToSlide;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit|MovementCancel")
    FHazePlayBlendSpaceData JogCancelBS;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit|MovementCancel")
    FHazePlayBlendSpaceData RunCancelBS;

	UPROPERTY(BlueprintReadOnly, Category = "DashExit|MovementCancel")
    FHazePlayBlendSpaceData SprintCancelBS;

	UPROPERTY(Category = "Action|StepDash")
	FHazePlaySequenceData FwdToActionMhLeftFoot;

	UPROPERTY(Category = "Action|StepDash")
	FHazePlaySequenceData FwdToActionMh;

	UPROPERTY(BlueprintReadOnly, Category = "Action|Dash")
    FHazePlaySequenceData DashToActionMhLeftFoot;

    UPROPERTY(BlueprintReadOnly, Category = "Action|Dash")
    FHazePlaySequenceData DashToActionMh;
}

class ULocomotionFeatureDash : UHazeLocomotionFeatureBase
{
	default Tag = n"Dash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDashAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph

	UPROPERTY(Category = "UseDashFootVariations")
	bool UseLeftOrRightFootVariations = false;

	UPROPERTY(Category = "Action")
	bool bUseActionMH = false;


}
	enum EDashFoot
	{
		LeftStepDash,
		RightStepDash,

	}
