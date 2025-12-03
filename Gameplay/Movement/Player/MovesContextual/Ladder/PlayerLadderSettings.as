class UPlayerLadderSettings : UHazeComposableSettings
{
	UPROPERTY(Category = LadderSettings)
	float VerticalDeadZone = 0.3;

	UPROPERTY(Category = LadderSettings)
	float HorizontalDeadZone = 0.3;

	/** Climbing Settings */
	const float ClimbUpSpeed = 167.0;

	/*	EnterSettings	*/
	
	const float EnterFromTopDuration = 0.6;

	const float EnterFromTopCapsuleOffsetDuration = 0.3;

	const float EnterFromTopInputCutoff = 30;

	//Degree cutoff for enter forward animation
	const float EnterFromTopForwardAngleCutoff = 25;

	//When entering from airborne/wallrun
	const float EnterMidLadderTime = 0.15;

	const float EnterFromGroundTotalTime = 0.4;

	// How long moving the capsule into position takes
	const float EnterFromGroundTranslationTime = 0.2;

	/*	ExitSettings	*/

	const float LetGoDuration = 0.2;

	const float BottomExitDuration = 0.2;

	const float TopExitDuration = 0.4;

	const float JumpOutAnticipationDelay = 0.15;

	const float JumpExitNoInputTime = 0.25;

	const float ExitInputBlendInTime = 0.75;

	const float JumpHorizontalDrag = 1.2;
	const float JumpGravityBlendInTime = 0.4;

	// How long should we block Jumpout when just entering ladder climb
	const float JumpOutInitialBlockedDuration = 0.5;

	/*	MovementSettings	*/
	const float TerminalSlideSpeed = 1500;

	//If down input is given, this is applied
	const float SlideGravityScalar = 0.30;

	// When no longer inputting slide down, decelerate at this speed
	const float SlideDecelerationSpeed = 1000.0;

	/** Ladder Dash Settings */
	const float LadderDashCooldown = 0.125;
	const float LadderDashDuration = 0.4;
	const float LadderDashAccelerationDuration = 0.05;
	const float LadderDashDecelerationDuration = 0.20;
	const float LadderDashDistance = 240.0;

	/** Ladder Transfer Settings */
	const float TransferMaxDistance = 350;
	const float TransferUpDuration = 0.4;
	const float TransferUpAccelerationDuration = 0.05;
	const float TransferUpDecelerationDuration = 0.20;
}