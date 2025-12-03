class UPlayerCrouchSettings : UHazeComposableSettings
{
	// Horizontal speed at maximum input
	UPROPERTY()
	float MaximumSpeed = 250.0;

	UPROPERTY()
	float SprintMaximumSpeed = 350.0;

	// Horizontal speed at minimum input
	UPROPERTY()
	float MinimumSpeed = 150.0;

	UPROPERTY()
	float SprintMinimumSpeed = 250;
	
	// How fast you get up to MoveSpeed
	UPROPERTY()
	float Acceleration = 1000.0;

	// If we are standing to far out on an edge
	// this is the min speed we will use to fall of
	UPROPERTY()
	float FallOfEdgeMinSpeed = 50.0;

	// Capsule half height when crouching
	UPROPERTY()
	float CapsuleHalfHeight = 38.0;


	// Interp speed to new speed when speeding up
	const float AccelerateInterpSpeed = 6.0;

	// Interp speed to new speed when slowing down
	const float SlowDownInterpSpeed = 4.0;

	// The minimum input the player can give, when above 0
	const float MinimumInput = 0.4;

	const float FacingDirectionInterpSpeed = 9.0;
}