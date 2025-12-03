class UPlayerCarChaseDiveSettings : UHazeComposableSettings
{
	// Target horizontal speed
	UPROPERTY()
	float HorizontalMoveSpeed = 500.0;

	// Interp speed of your velocity (units per second)
	UPROPERTY()
	float HorizontalVelocityInterpSpeed = 14000.0;
	
	// At this speed and below, the player will have 100% turning rate
	UPROPERTY()
	float MaximumTurnRateFallingSpeed = 1200.0;

	// The speed at which the player will have minimum turn rate (lerped between max as the player increases falling speed)
	UPROPERTY()
	float MinimumTurnRateFallingSpeed = 1800.0;
	

	// Rotation speed of the player towards your input
	float MaximumTurnRate = 8.0;
	float MinimumTurnRate = 1.0;
}