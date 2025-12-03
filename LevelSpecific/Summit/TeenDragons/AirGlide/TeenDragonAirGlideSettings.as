class UTeenDragonAirGlideSettings : UHazeComposableSettings
{
	// Minimum duration for gliding after pressing the button
	UPROPERTY(Category = "Duration")
 	float GlideMinimumDuration = 0.5;
	UPROPERTY(Category = "Duration")
	float GlideCooldown = 0.2;


	// How fast to change facing rotation while gliding
	UPROPERTY(Category = "Rotation")
	float FacingDirectionInterpSpeed = 1.5;
	// How fast the wanted rotation updates with input (which the dragon rotation & camera accelerates towards)
	UPROPERTY(Category = "Rotation")
	float GlideRotationSpeed = 30.0;

	// Max vertical velocity for the player while gliding
	UPROPERTY(Category = "Speed")
	float GlideMaxVerticalSpeed = 450.0;

	UPROPERTY(Category = "Speed")
	float VerticalVelocityAccelerationDuration = 1.5;
	// How fast we accelerate towards our input
	UPROPERTY(Category = "Speed")
	float HorizontalSpeedInterpSpeed = 2.0;
	// Max speed
	UPROPERTY(Category = "Speed")
	float GlideHorizontalMaxMoveSpeed = 2100.0;

	/** How much vertical air boost you gain when first activating glide
	(Recovers on landing)*/
	UPROPERTY(Category = "Initial Air Boost")
	float InitialAirBoostSize = 1700.0;

	/** How fast the initial air boost is applied */
	UPROPERTY(Category = "Initial Air Boost")
	float InitialAirBoostApplicationDuration = 0.5;

	/** Over which velocity the air boost is not added */
	UPROPERTY(Category = "Initial Air Boost")
	float InitialAirBoostMaxVelocity = 1500.0;

	UPROPERTY(Category = "Initial Air Boost")
	FHazeCameraImpulse InitialAirBoostCameraImpulse;
	default InitialAirBoostCameraImpulse.WorldSpaceImpulse = FVector(0.0, 0.0, -2000.0);
	default InitialAirBoostCameraImpulse.Dampening = 1.0;
	default InitialAirBoostCameraImpulse.ExpirationForce = 7.5;

	UPROPERTY(Category = "Initial Air Boost")
	float InitialAirBoostGravityAmount = 2025.0;

	UPROPERTY(Category = "Camera")
	float GlideCameraAccelerationSpeed = 0.5;

	// Time axle : 0 - 1 Fraction of speed between 0 and maximum speed
	// Value axle : How much Speed Effect is played on the camera
	UPROPERTY(Category = "Camera")
	FRuntimeFloatCurve SpeedEffectValue;
	default SpeedEffectValue.AddDefaultKey(0, 0);
	default SpeedEffectValue.AddDefaultKey(0.5, 0);
	default SpeedEffectValue.AddDefaultKey(1, 0.5);

	// Time axle : 0 - 1 Fraction of speed between 0 and maximum speed
	// Value axle : How much the camera blends the FOV
	UPROPERTY(Category = "Camera")
	FRuntimeFloatCurve FOVSpeedScale;
	default FOVSpeedScale.AddDefaultKey(0, 0);
	default FOVSpeedScale.AddDefaultKey(1, 1);

	// Time axle : 0 - 1 Fraction of speed between 0 and maximum speed
	// Value axle : How much the camera shake is scaled
	UPROPERTY(Category = "Camera")
	FRuntimeFloatCurve CameraShakeScale;
	default CameraShakeScale.AddDefaultKey(0, 0);
	default CameraShakeScale.AddDefaultKey(0.7, 0);
	default CameraShakeScale.AddDefaultKey(1, 1);

	// Seconds until the hover camera settings are blended in
	UPROPERTY(Category = "Camera")
	float HoverCameraSettingsBlendInTime = 1.2;

	// Seconds until the hover camera settings are blended out
	UPROPERTY(Category = "Camera")
	float HoverCameraSettingsBlendOutTime = 1.2;

	UPROPERTY(Category = "Camera")
	float MaxCameraYaw = 90;

	UPROPERTY(Category = "Camera")
	float MaxCameraPitch = 60;

	UPROPERTY(Category = "Camera")
	float InputCameraRotationDuration = 2.0;

	// Seconds until the ring boost camera settings are blended out
	// Blend in is based on boost duration
	UPROPERTY(Category = "Camera")
	float RingBoostCameraBlendOutTime = 3.5;

	UPROPERTY(Category = "Camera Follow")
	float CameraFollowSpeed = 1.0;
	
	UPROPERTY(Category = "Camera Follow")
	float CameraInputStopFollowDuration = 1.5;

	UPROPERTY(Category = "Camera Follow")
	float CameraFollowMinSpeed = 500.0;
}