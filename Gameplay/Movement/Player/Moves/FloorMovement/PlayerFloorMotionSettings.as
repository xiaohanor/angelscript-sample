class UPlayerFloorMotionSettings : UHazeComposableSettings
{
	// Horizontal speed at maximum input
	UPROPERTY()
	float MaximumSpeed = 500.0;

	// Maximum speed we achieve after we've been running for a while
	UPROPERTY()
	float MaximumSpeedAfterPeriod = 550.0;

	// Horizontal speed at minimum input
	UPROPERTY()
	float MinimumSpeed = 150.0;
	
	// How fast to accelerate up to move speed from 
	UPROPERTY()
	float Acceleration = 1500.0;

	// How fast to decelerate when we are moving faster than our wanted movespeed
	UPROPERTY()
	float Deceleration = 3500.0;

	// If we are standing to far out on an edge
	// this is the min speed we will use to fall of
	UPROPERTY()
	float FallOfEdgeMinSpeed = 275.0;

	// The minimum input the player can give, when above 0
	const float MinimumInput = 0.4;

	UPROPERTY(Category = "Advanced - Do not change for general gameplay")
	float FacingDirectionInterpSpeed = 11.0;

	// After we've been running at full speed for this long, start increasing speed
	UPROPERTY()
	float SpeedIncreasePeriodStart = 1.0;

	// How long we need to be running at full speed after the speed increase period starts to reach the new maximum
	UPROPERTY()
	float SpeedIncreasePeriodDuration = 2.0;
}