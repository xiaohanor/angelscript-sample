class UPlayerAirDashSettings : UHazeComposableSettings
{
	//The timeframe after initiating the move where we can freely snap rotation towards stick input.
	UPROPERTY(Category = "Settings")
	float RedirectionWindow = 0.0;

	UPROPERTY(Category = "Settings")
	float InputBufferWindow = 0.08;

	UPROPERTY(Category = "Settings")
	float DashDuration = 0.1666;

	UPROPERTY(Category = "Settings")
	float DashAccelerationDuration = 0.05;

	UPROPERTY(Category = "Settings")
	float DashDecelerationDuration = 0.05;

	// How long gravity should be active during the dash (counted from the end of the dash)
	UPROPERTY(Category = "Settings")
	float GravityDurationAtEnd = 0.1;

	UPROPERTY(Category = "Settings")
	float DashDistance = 250.0;

	//How much we overspeed our airmotion speed when exiting dash
	UPROPERTY(Category = "Settings")
	float DashExitOverSpeed = 150;

	// Angle from forward that this becomes a pure step rather than a strafe
	UPROPERTY(Category = "Settings")
	float ForwardDashAngle = 50.0;

	// Angle from backward that this becomes a pure step rather than a strafe
	UPROPERTY(Category = "Settings")
	float BackwardDashAngle = 65.0;

	// How fast to interp the rotation when dashing forward
	UPROPERTY(Category = "Settings")
	float ForwardStepRotationInterpSpeed = 4.0 * PI;

	// Amount of time that it takes to complete turning when specifically doing a sidestep
	UPROPERTY(Category = "Settings")
	float SideStepRotationDuration = 0.1;
}