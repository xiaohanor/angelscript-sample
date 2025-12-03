class UPlayerGrappleSettings : UHazeComposableSettings
{
	/**
	 * EnterSettings
	 */
	UPROPERTY(Category = General)
	float GrappleEnterDuration = 0.35;
	
	float EnterCameraBlendInTimeMultiplier = 1;

	float MinEnterIdealDistance = 375;

	float HorizontalPivotOffset = 75;

	float VerticalPivotOffset = 125;

	//When during the move will the grapple throw start (As an alpha between 0 - 1)
	float CableStartAlpha = 0.65;

	UPROPERTY(Category = General)
	float GrappleDuration = 1.05;

	UPROPERTY(Category = General)
	float GrappleArcDuration = 1.05;

	UPROPERTY(Category = Launch)
	float GrappleLaunchDuration = 1.55;

	// Speed when starting to launch
	UPROPERTY(Category = Launch)
	float GrappleLaunchEnterSpeed = 3500.0;

	//Speed when starting slide grapple, accelerates into the point launch velocity
	UPROPERTY(Category = Slide)
	float GrappleSlideEnterSpeed = 3250;

	/**
	 * Grapple Bash Settings
	 */

	// Starting speed to launch towards the bash point with
	UPROPERTY(Category = Bash)
	float GrappleBashEnterStartSpeed = 1000;

	// Maximum speed to launch towards the bash point with
	UPROPERTY(Category = Bash)
	float GrappleBashEnterMaxSpeed = 2500;

	// Acceleration to launch towards the bash point with
	UPROPERTY(Category = Bash)
	float GrappleBashEnterAcceleration = 1000;

	// How long is the player frozen to aim the launch
	UPROPERTY(Category = Bash)
	float GrappleBashMaxAimDuration = 1.2;

	/**
	 * If the player holds the same aim direction for this duration,
	 * complete the aiming early without waiting the full duration and just go there.
	 */
	UPROPERTY(Category = Bash)
	float GrappleBashAimLockInTimer = 0.5;

	/**
	 * GrappleToPoint Settings
	 */
	UPROPERTY(Category = Advanced)
	float GrappleToPointAccelerationDuration = 0.18;

	UPROPERTY(Category = Advanced)
	float GrappleToPointTopVelocity = 3250;

	//Minimum angle difference required when above target for a grapple to ground move
	const float GrappleToGroundAngleLimit = -10;
	//Minimum angle difference required when below the target to count as roughly perpendicular
	const float GrappleToJumpOverAngle = 20;

	//To Point Exit Settings

	const float EnterOffsetFromWall = 150;

	const float InwardsTraceDistance = 200;

	const float GroundedInwardsTraceDistance = 100;

	const float GrappleToPointExitDuration = 0.75;

	//How far off the ground do we peak vertically
	const float GrappleToPointExitHeightOffset = 100;

	//To Point Ground Exit

	const float GrappleToPointGroundedExitSpeed = 750;

	/** Grapple Slide Settings */

	const float GrappleToSlideAccelerationDuration = 0.12;

	const float GrappleToSlideMaximumHeightCutoff = 200;


	/** Grapple To Perch Settings */

	const float TriggerLandingDistance = 800;

	const float EnterOffsetFromPerch = 800;

	const float GrappleToPerchAbovePointAngleCutoff = 5;

	//Grapple Cable Retract settings
	//
	const float GRAPPLE_REEL_DURATION = 0.12;
	//
	const float GRAPPLE_REEL_DELAY = 0.18;
}