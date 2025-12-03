class UTeenDragonLandingCameraSettings : UHazeComposableSettings
{
	UPROPERTY()
	float CameraImpulsePerSpeedIntoLanding = 0.5;

	UPROPERTY()
	float CameraImpulseMaxSize = 2000.0;

	UPROPERTY()
	float CameraImpulseMinSize = 200.0;

	UPROPERTY()
	float CameraImpulseExpirationForce = 25.0;

	UPROPERTY()
	float CameraImpulseDampening = 1.0;

	UPROPERTY()
	float DelayBeforeFullCameraImpulse = 1.0;
}