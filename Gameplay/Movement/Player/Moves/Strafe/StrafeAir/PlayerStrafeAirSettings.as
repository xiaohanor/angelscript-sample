class UPlayerStrafeAirSettings : UHazeComposableSettings
{
	// Target horizontal speed
	UPROPERTY()
	float HorizontalMoveSpeed = 500.0;

	// Interp speed of your velocity (units per second)
	UPROPERTY()
	float HorizontalVelocityInterpSpeed = 1800.0;	
}