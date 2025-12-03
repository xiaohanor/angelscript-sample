class UPlayerSlideJumpSettings : UHazeComposableSettings
{
	// Horizontal speed when jumping
	UPROPERTY()
	float HorizontalSpeed = 1200.0;

	// Vertical impulse
	UPROPERTY()
	float VerticalImpulse = 1200.0;

	// Time it takes to slowdown before leaving the ground
	UPROPERTY()
	float SlowdownTime = 0.001;
	
	// Horizontal speed to slow down to before leaving the ground
	UPROPERTY()
	float SlowdownSpeed = 1000.0;

	// Interp speed of your velocity (units per second)
	UPROPERTY()
	float HorizontalVelocityInterpSpeed = 1800.0;

	// Rotation speed of the player towards your input
	UPROPERTY()
	float FacingDirectionInterpSpeed = 8.0;

	// Target horizontal speed
	UPROPERTY()
	float HorizontalMoveSpeed = 1000.0;

}