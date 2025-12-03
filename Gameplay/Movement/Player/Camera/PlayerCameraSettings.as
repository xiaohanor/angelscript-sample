
class UPlayerCameraSettings : UHazeComposableSettings
{
	// How long it will take for the camera to align with the
	// players current world up.
	// Used by 'PlayerAlignCameraWithWorldUpCapability'
	UPROPERTY(Category = "Camera")
	float AlignCameraWithWorldUpDuration = 0.5;
}