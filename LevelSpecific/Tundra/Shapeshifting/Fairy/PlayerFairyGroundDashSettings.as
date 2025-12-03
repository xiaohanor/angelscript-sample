class UPlayerFairyGroundDashSettings : UHazeComposableSettings
{
	//The timeframe after initiating the move where we can freely snap rotation towards stick input.
	UPROPERTY(Category = "Settings")
	float RedirectionWindow = 0.0;

	UPROPERTY(Category = "Settings")
	float InputBufferWindow = 0.08;

	UPROPERTY(Category = "Settings")
	float DashDuration = 0.5;

	UPROPERTY(Category = "Settings")
	float DashAccelerationDuration = 0.02;

	UPROPERTY(Category = "Settings")
	float DashDecelerationDuration = 0.05;

	UPROPERTY(Category = "Settings")
	float DashCooldown = 0.6;

	UPROPERTY(Category = "Settings")
	float StepDistance = 600.0;

	// Exit Speed after the step dash is done
	UPROPERTY(Category = "Settings")
	float ExitSpeed = 500.0;

	// Exit speed if we were sprinting when we dashed
	UPROPERTY(Category = "Settings")
	float ExitSpeedSprinting = 600.0;

	// Angle from forward that this becomes a pure step rather than a strafe
	UPROPERTY(Category = "Settings")
	float ForwardStepAngle = 50.0;

	// Angle from backward that this becomes a pure step rather than a strafe
	UPROPERTY(Category = "Settings")
	float BackwardStepAngle = 65.0;

	// How fast to interp the rotation when dashing forward
	UPROPERTY(Category = "Settings")
	float ForwardStepRotationInterpSpeed = 4.0 * PI;

	// Amount of time that it takes to complete turning when specifically doing a sidestep
	UPROPERTY(Category = "Settings")
	float SideStepRotationDuration = 0.1;

	// Linger time for the camera settings after the dash is done
	UPROPERTY(Category = "Settings")
	float CameraSettingsLingerTime = 0.1;
}