class UBattlefieldHoverboardCameraControlSettings : UHazeComposableSettings
{

	/* How fast the camera rotates towards the wanted rotation
	Set lower than the Rotation Duration in the capabilities to have the camera (look ahead)*/
	UPROPERTY()
	float RotationDuration = 1.2;

	// How long until the camera settings blends in and out
	UPROPERTY()
	float SettingsBlendTime = 0.5;

	/* How long it takes for the camera pitch to go towards the velocity's pitch
	(How fast the camera turns in slopes upwards and downwards)*/
	UPROPERTY()
	float VelocityPitchInterpDuration = 4.0;

	/* The maximum pitch the camera can have upwards and downwards towards the velocity*/
	UPROPERTY()
	float VelocityPitchMin = -25.0;
	
	UPROPERTY()
	float VelocityPitchMax = 25.0;

	/* How far it traces bellow the board to find ground to check if it should rotate with pitch after jump
	as well as to angle the pitch min and max along */
	UPROPERTY()
	float VelocityPitchGroundTraceDistance = 700.0;
	
	/* The maximum rotation you can achieve with full input in any direction*/
	UPROPERTY(Category = "Snapback Input")
	FRotator InputRotationMax(25, 50, 0);

	// How long it takes for the input rotation to reach the input
	UPROPERTY(Category = "Snapback Input")
	float InputRotationDuration = 2.2;

	/* How long it waits before rotating back after letting go of stick */
	UPROPERTY(Category = "Snapback Input")
	float NoInputRotateBackDelay = 0.25;

	/* How long it takes for the input rotation to go back when there is no input */
	UPROPERTY(Category = "Snapback Input")
	float NoInputRotateBackDuration = 4.0;

	/* How much the camera gets offset towards the input
	X -> Forward based on Yaw 
	Y -> Either Side based on Yaw*/
	UPROPERTY(Category = "Turning Offset")
	FVector MaxTurningOffset = FVector(75, 125, 0);

	/* How fast the turning offset updates */
	UPROPERTY(Category = "Turning Offset")
	float TurningOffsetSpeed = 2.0;

	/* The maximum the camera can tilt towards the input sideways direction
	(In degrees from world up) */
	UPROPERTY(Category = "Turning Tilt")
	float TurningTiltMax = 5.5;

	/* How long the turning tilt takes to update
	(In seconds to reach the target) */
	UPROPERTY(Category = "Turning Tilt")
	float TurningTiltSpeed = 2.0;


	/* Camera Settings that get blended in based on how fast the hoverboard is going compared to the max
	0.0 (Min speed) -> 1.0 (Max Speed)*/
	UPROPERTY(Category = "Speed Effects")
	UHazeCameraSettingsDataAsset CameraSpeedSettings;

	/* Curve of how much speed effect gets applied to the camera
	Time Axle : 0.0 (Min speed) -> 1.0 (Max Speed)
	Value Axle : How much speed effect gets applied*/
	UPROPERTY(Category = "Speed Effects")
	FRuntimeFloatCurve SpeedEffectCurve;
	default SpeedEffectCurve.AddDefaultKey(0.0, 0.0);
	default SpeedEffectCurve.AddDefaultKey(0.5, 0.0);
	default SpeedEffectCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(Category = "Speed Effects")
	float MinSpeedEffectSpeed = 2000.0;

	UPROPERTY(Category = "Speed Effects")
	float MaxSpeedEffectSpeed = 2800.0;

	/** How much of the speed aligned with world up  */
	UPROPERTY(Category = "Landing Impulse")
	float LandingImpulseMultiplier = 0.6;

	UPROPERTY(Category = "Landing Impulse")
	float LandingImpulseMaxSize = 3000.0;

	UPROPERTY(Category = "Landing Impulse")
	float LandingImpulseExpirationForce = 12;
}