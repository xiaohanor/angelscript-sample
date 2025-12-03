class UPlayerUnwalkableSlideSettings : UHazeComposableSettings
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

	// If we are standing to far out on an edge
	// this is the min speed we will use to fall of
	UPROPERTY()
	float FallOfEdgeMinSpeed = 275.0;


	// Interp speed to new speed when speeding up
	const float AccelerateInterpSpeed = 4.0;

	// Interp speed to new speed when slowing down
	const float SlowDownInterpSpeed = 3.0;

	// The minimum input the player can give, when above 0
	const float MinimumInput = 0.4;

	const float FacingDirectionInterpSpeed = 11.0;
}