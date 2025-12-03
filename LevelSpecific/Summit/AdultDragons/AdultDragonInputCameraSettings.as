class UAdultDragonInputCameraSettings : UHazeComposableSettings
{
	// The maximum you are allowed to yaw left and right with the camera controls
	UPROPERTY()
	float InputCameraMaxYaw = 30;

	// The maximum you are allowed to pitch up and down with the camera controls
	UPROPERTY()
	float InputCameraMaxPitch = 30;

	// How fast the camera rotates with the right stick
	UPROPERTY()
	float InputCameraRotationDuration = 1.5;
}