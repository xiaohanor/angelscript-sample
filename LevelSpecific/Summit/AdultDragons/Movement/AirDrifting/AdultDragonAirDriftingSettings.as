class UAdultDragonAirDriftingSettings : UHazeComposableSettings
{
	// How fast the wanted yaw is updated
	UPROPERTY()
	float WantedYawSpeed = 115;

	// How fast the wanted pitch is updated
	UPROPERTY()
	float WantedPitchSpeed = 90;

	// The maximum the dragon can pitch up or down
	UPROPERTY()
	float PitchMaxAmount = 70;

	// How fast the dragon rotates towards the wanted rotation while there is no steering input
	// Only for velocity direction, rotation of dragon is handled by drift rotation speed
	UPROPERTY()
	float RotationDuration = 1.0;

	// How fast the dragon rotates towards the wanted rotation while there is steering input
	// Only for velocity direction, rotation of dragon is handled by drift rotation speed
	UPROPERTY()
	float RotationDurationDuringInput = 2.0;

	UPROPERTY()
	float CameraBlendInDuration = 2.0;

	UPROPERTY()
	float CameraBlendOutDuration = 2.0;	

	// How long of turning above the threshold you need before drifting activates
	// it resets after not turning
	UPROPERTY()
	float TurningTimerActivation = 0.4;

	// Threshold above which the timer kicks in, after which the drifting activates
	// Size of steering vector 0 -> 1 
	UPROPERTY()
	float SteeringTurningThreshold = 0.9;

	// TURNING CAMERA OFFSET
	
	// How much the camera offsets forward when turning
	// Based on the yaw of the steering
	UPROPERTY()
	float ForwardTurningCameraOffsetMax = -300;

	// How much the camera offsets to the right when turning
	// Based on the yaw of the steering
	UPROPERTY()
	float RightTurningCameraOffsetMax = 300;

	// How much the camera offsets up when turning
	// Based on the pitch of the steering
	UPROPERTY()
	float UpTurningCameraOffsetMax = 300;

	// How fast the turning offset accelerates
	UPROPERTY()
	float TurningOffsetSpeed = 3.0;
}