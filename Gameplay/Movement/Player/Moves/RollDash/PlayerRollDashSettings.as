class UPlayerRollDashSettings : UHazeComposableSettings
{
	// How long after the step dash the roll dash is available
	UPROPERTY(Category = "Settings")
	float MaxAvailableTimeAfterStep = 0.5;

	// Buffer any pressed rolls until at least this amount of time has passed after a step ash
	UPROPERTY(Category = "Settings")
	float BufferUntilTimeAfterStep = 0.2;

	// If the roll was pressed at least this amount of time _after_ the step dash, boost it
	UPROPERTY(Category = "Settings")
	float BoostFromTimeAfterStep = 0.3;

	//The timeframe after initiating the move where we can freely snap rotation towards stick input.
	UPROPERTY(Category = "Settings")
	float RedirectionWindow = 0.00;

	UPROPERTY(Category = "Settings")
	float InputBufferWindow = 0.08;

	UPROPERTY(Category = "Settings")
	float DashDuration = 0.3333;

	UPROPERTY(Category = "Settings")
	float BoostedDashDuration = 0.3333;

	UPROPERTY(Category = "Settings")
	float DashAccelerationDuration = 0.03;

	UPROPERTY(Category = "Settings")
	float DashDecelerationDuration = 0.1;

	UPROPERTY(Category = "Settings")
	float DashCooldown = 0.3;

	UPROPERTY(Category = "Settings")
	float DashDistance = 300.0;

	UPROPERTY(Category = "Settings")
	float BoostedDashDistance = 300.0;

	// Exit Speed after the dash is done
	UPROPERTY(Category = "Settings")
	float ExitSpeed = 500.0;

	// Exit speed if we were sprinting when we dashed
	UPROPERTY(Category = "Settings")
	float ExitSpeedSprinting = 700.0;

	// How fast to interp the rotation when dashing
	UPROPERTY(Category = "Settings")
	float RotationInterpSpeed = 4.0 * PI;

	// How long to be in 'blocked roll state' after starting the dash, which prevents interruption from things like Jumps
	UPROPERTY(Category = "Settings")
	float BlockedRollStateDuration = 0.2;

	/*** RollDashJump Settings ***/

	UPROPERTY(Category = "RollDashJump Settings")
	float MaxAvailableTimeAfterRoll = 0.39;

	UPROPERTY(Category = "RollDashJump Settings")
	float TimeBeforeRollDashJumpAvailable = 0.09;

	//How much we multiply our vertical velocity based on normal jump impulse
	UPROPERTY(Category = "RollDashJump Settings")
	float VerticalVelocityMultiplier = 1.0;

	//How long we hold for anticipation prior to jump
	UPROPERTY(Category = "RollDashJump Settings")
	float RollDashJumpAnticipationDuration = 0.066;

	//How much we decelerate our speed prior to "Launching"
	UPROPERTY(Category = "RollDashJump Settings")
	float MinimumSlowdownVelocity = 300;

	//How much we accelerate to
	UPROPERTY(Category = "RollDashJump Settings")
	float PeakHorizontalVelocity = 900;

	//How long we accelerate for
	UPROPERTY(Category = "RollDashJump Settings")
	float AccelerationDuration = 0.15;
}