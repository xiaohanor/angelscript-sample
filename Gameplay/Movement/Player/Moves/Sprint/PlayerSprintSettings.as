class UPlayerSprintSettings : UHazeComposableSettings
{
	// Horizontal speed at maximum input
	UPROPERTY(Category = "Sprint Settings")
	float MaximumSpeed = 700.0;

	// Horizontal speed at minimum input
	UPROPERTY(Category = "Sprint Settings")
	float MinimumSpeed = 500.0;

	// How fast to accelerate up to sprint speed from 
	UPROPERTY(Category = "Sprint Settings")
	float Acceleration = 2000.0;

	// How fast to decelerate when we are moving faster than our wanted sprint speed
	UPROPERTY(Category = "Sprint Settings")
	float Deceleration = 1500.0;

	UPROPERTY(Category = "Sprint Settings", AdvancedDisplay)
	float FacingDirectionInterpSpeed = 11.0;

	// How long the camera settings should fully linger before being blended out after we exit sprint
	UPROPERTY(Category = "Camera Settings")
	float CameraSettingsLingerTime = 3.0;

	//Turnaround settings
	const float TurnAroundSlowdownDuration = 0.4;
	const float TurnAroundSpeedupDuration = 0.25;

	// The minimum input the player can give, when above 0
	const float MinimumInput = 0.4;

	//Overspeed settings
	const float AdditionalActivationSpeed = 300;
	const float OverspeedAccelerationDuration = 0.2;
	const float OverspeedDeccelerationDuration = 0.8;
}