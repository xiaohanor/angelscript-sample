namespace PlayerPoleClimbTags
{
	const FName PoleClimbEnter = n"PoleClimbEnter";
	const FName PoleClimbMovement = n"PoleClimbMovement";
	const FName PoleClimbCancel = n"PoleClimbCancel";
	const FName PoleClimbJumpOut = n"PoleClimbJumpOut";
	const FName PoleClimbDash = n"PoleClimbDash";
	const FName PoleClimbExitToPerch = n"PoleClimbExitToPerch";
	const FName PoleClimbEnterFromPerch = n"PoleClimbEnterFromPerch";
	const FName PoleClimbTurnaround = n"PoleClimbTurnaround";
}

namespace PoleClimb
{
	const bool bEnable2DPoleClimb = false;
	const bool bJumpOffInInputDirection = true;
	const bool bRememberWantedDirectionWhenLosingInput = true;
	const bool bUseAlternateClimbControls = false;
}