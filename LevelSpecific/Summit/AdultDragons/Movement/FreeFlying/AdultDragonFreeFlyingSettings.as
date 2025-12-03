namespace AdultDragonFreeFlying
{
	asset AdultDragonFreeFlightSettings of UAdultDragonFreeFlightSettings
	{
		PitchMaxAmount = 40;
		PitchMinAmount = -80;
		PitchRotationDuration = 2.25;
		WantedYawSpeed = 62;
		MoveSpeedRange = FHazeRange(10000, 14000);
	}

	const bool bKillPlayerOutsideBoundary = true;
}

class UAdultDragonFreeFlightSettings : UHazeComposableSettings
{
	// Acceleration if below minimum speed
	UPROPERTY()
	float Acceleration = 2800.0;

	UPROPERTY()
	FHazeRange MoveSpeedRange(10000, 16000);

	// The amount of speed gained per second per degree while going downwards
	UPROPERTY()
	float SpeedGainedGoingDown = 15;

	// The amount of speed lost per second per degree while going upwards
	UPROPERTY()
	float SpeedLostGoingUp = 15;

	// How fast the wanted yaw is updated
	UPROPERTY()
	float WantedYawSpeed = 75.0;

	// The maximum the dragon can pitch up
	UPROPERTY()
	float PitchMaxAmount = 60;

	// The maximum the dragon can pitch down (negative value)
	UPROPERTY()
	float PitchMinAmount = -60;

	// How fast the dragon rotates towards the wanted rotation while there is steering input
	UPROPERTY()
	float PitchRotationDuration = 3.0;

	// Seconds until the normal camera settings are blended in
	// Not applied to the special settings that are based on speed fraction
	UPROPERTY()
	float CameraBlendInTime = 2.0;

	// Seconds until camera is fully blended out to normal
	UPROPERTY()
	float CameraBlendOutTime = 3.5;

	// How fast the camera turns towards the wanted rotation
	// Measured in seconds until it reaches it's target
	UPROPERTY()
	float CameraAcceleration = 3.5;

	// Time axle : 0 - 1 Fraction of speed between minimum and maximum speed
	// Value axle : How much the camera shake is scaled
	UPROPERTY()
	FRuntimeFloatCurve CameraShakeAmount;
	default CameraShakeAmount.AddDefaultKey(0, 0);
	default CameraShakeAmount.AddDefaultKey(0.4, 0);
	default CameraShakeAmount.AddDefaultKey(1, 1);

	// Time axle : 0 - 1 Fraction of speed between minimum and maximum speed
	// Value axle : How much Speed Effect is played on the camera
	UPROPERTY()
	FRuntimeFloatCurve SpeedEffectValue;
	default SpeedEffectValue.AddDefaultKey(0, 0);
	default SpeedEffectValue.AddDefaultKey(0.35, 0.0);
	default SpeedEffectValue.AddDefaultKey(1, 0.4);

	// Time axle : 0 - 1 Fraction of speed between minimum and maximum speed
	// Value axle : How much the camera blends the FOV
	UPROPERTY()
	FRuntimeFloatCurve FOVSpeedScale;
	default FOVSpeedScale.AddDefaultKey(0, 0);
	default FOVSpeedScale.AddDefaultKey(1, 1);

	// TURNING CAMERA OFFSET

	// How much the camera offsets forward when turning
	// Based on the yaw of the steering
	UPROPERTY()
	float ForwardTurningCameraOffsetMax = -0;

	// How much the camera offsets to the right when turning
	// Based on the yaw of the steering
	UPROPERTY()
	float RightTurningCameraOffsetMax = 0.0;

	// How much the camera offsets up when turning
	// Based on the pitch of the steering
	UPROPERTY()
	float UpTurningCameraOffsetMax = 0.0;

	// How fast the turning offset accelerates
	UPROPERTY()
	float TurningOffsetSpeed = 8.5;

	// CAMERA TILT

	// How much the camera can tilt with maximum input
	UPROPERTY()
	float CameraTiltMax = 5.0;

	// How long it takes until it tilts towards the target
	UPROPERTY()
	float CameraTiltDuration = 1.5;

	/* How much speed is lost when flying into a wall
	If set to 1, all speed is lost with a full on collision*/
	UPROPERTY()
	float CollisionSpeedLossMultiplier = 1.0;
}