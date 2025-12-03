class UPlayerStrafeFloorSettings : UHazeComposableSettings
{
	// Horizontal speed at maximum input
	UPROPERTY()
	float MaximumSpeed = 500.0;

	// Horizontal speed at minimum input
	UPROPERTY()
	float MinimumSpeed = 275.0;
	
	// How fast you get up to MoveSpeed
	UPROPERTY()
	float Acceleration = 2400.0;


	// Interp speed to new speed when speeding up
	const float AccelerateInterpSpeed = 8.0;

	// Interp speed to new speed when slowing down
	const float DecelerateInterpSpeed = 6.0;

	// The minimum input the player can give, when above 0
	const float MinimumInput = 0.4;

	const float StationarySmoothAngleClamp = 45.0;

	const float StationaryStepTurnTime = 0.6;

	// The size of each rotation step
	const float StationaryStepAngle = 45.0;
	// How far the rotation can differ from the target
	const float StationaryStepCorrectionAngle = 22.5;
}