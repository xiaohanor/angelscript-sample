class UPlayerWallRunSettings : UHazeComposableSettings
{
	//How long after we leave a wallrun/ledge run can we still transfer
	const float TransferGraceWindow = 0.15;

	//Scoring requirement during evaluation for walls that allow both scramble and wallrun
	const float WallRunScrambleEvalWeight = 1.1;

	//Scoring requirement during evaluation for walls that only allow wallrun
	const float WallRunOnlyEvalWeight = 0.8;

	// The camera angle from the wall normal required for a wall run
	UPROPERTY()
	float RequiredCameraAngle = 27.5;

	// Input angle from the wall normal required for a wall run
	UPROPERTY()
	float RequiredInputAngle = 37.5;

	// Minimum and Maximum entry speed for standard entry
	UPROPERTY()
	float MinimumSpeed = 700.0;

	UPROPERTY()
	float MaximumSpeed = 700.0;

	UPROPERTY()
	float HorizontalBrakingDeceleration = 400.0;

	UPROPERTY()
	float GravityStrength = 375.0;
	
	UPROPERTY()
	float LedgeGrabTargetSpeed = 800.0;

	UPROPERTY()
	float LedgeGrabTargetSpeedInterpSpeed = 2.2;

	UPROPERTY()
	float ActivationWeight = 1.0;

	UPROPERTY()
	EPlayerWallRunJumpOverride JumpOverride = EPlayerWallRunJumpOverride::None;

	UPROPERTY()
	float InvalidWallOutwardsBoost = 150;

	UPROPERTY()
	float CameraPitch = -5.0;

	/**
	 * How long after starting a wallrun before we're able to jump off.
	 * Jump input before this threshold is ignored.
	 */
	UPROPERTY()
	float WallRunJumpOffInitialCooldown = 0.25;

	UPROPERTY()
	float WallRunJumpOffInheritVelocityScalar = 0;

	const float FacingRotationInterpSpeed = 180.0;

	// Radius of the trace towards the wall. Trace distance will be adjusted to compenstate for radius changes
	const float WallTraceSphereRadius = 25.0;	

	// If you don't override enter velocity, this is the default
	const float NonOverrideAngle = 15.0;
	const float NonOverrideSpeed = 1000.0;

	// If a trace of this distance hits, you will do the dash instead of a jump
	const float DashTraceDistance = 800.0;

	//** TurnAroundSettings **
	//
	float TurnaroundSlowDownDuration = 0.8;

	//
	float TurnaroundSpeedUpDuration = 0.6;

	// Minimum angle difference between the normals of two chained wall runs before we allow chaining them
	// This limits wall run chaining so it can only happen on reasonably oppositely-faced walls
	const float MinimumWallRunChainAngle = 100.0;
	// If we chain wall runs, enforce the height limit by increasing gravity this much
	const float HeightLimitPullDownVelocity = 700.0;
}

enum EPlayerWallRunJumpOverride
{
	None,
	ForceJump,
	ForceTransfer,
	ForceForwardJump
}