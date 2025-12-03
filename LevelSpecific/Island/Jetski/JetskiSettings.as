enum EJetskiCameraMode
{
	// The camera will follow the spline direction (if no input is given)
	Spline,

	// The camera is fully controlled by the player
	Free,

	// Look in the direction of CameraLook components
	Look
};

enum EJetskiSteeringMode
{
	// The jetski rotates around the vertical axis when steering
	Rotate,

	// The jetski will move left/right relative to the spline when steering
	Spline,
};

class UJetskiSettings : UHazeComposableSettings
{
    // Camera

	UPROPERTY(Category = "Camera")
	EJetskiCameraMode CameraMode = EJetskiCameraMode::Free;

	// How much we can look Left/Right
	UPROPERTY(Category = "Camera|Free")
	float FreeCameraYawLimit = 60;

	// How much we can look Up/Down
    UPROPERTY(Category = "Camera|Free")
	FVector2D FreeCameraPitchLimits = FVector2D(-40, 30);

	// How fast we reach the input desired rotation
    UPROPERTY(Category = "Camera|Free")
	float FreeCameraInputAccelerationDuration = 1.0;

	// How fast to reset to the follow direction
    UPROPERTY(Category = "Camera|Free")
	float FreeCameraFollowDuration = 0.75;

    UPROPERTY(Category = "Camera|Free")
	float FreeCameraFallFollowDuration = 2.0;

    UPROPERTY(Category = "Camera|Free")
	float FreeCameraFallDelay = 0.5;

    UPROPERTY(Category = "Camera|Free")
	float FreeCameraJumpLookDownAmount = 0.3;

    UPROPERTY(Category = "Camera|Free")
    float FreeCameraLeadAmount = 0;

	UPROPERTY(Category = "Camera|Free")
    float FreeCameraSurfacePitch = -20;

	UPROPERTY(Category = "Camera|Free")
    float FreeCameraSurfacePitchAccelerateDuration = 1;

	UPROPERTY(Category = "Camera|Free")
    float FreeCameraUnderwaterPitch = 10;

	UPROPERTY(Category = "Camera|Free")
    float FreeCameraUnderwaterPitchAccelerateDuration = 1;

    UPROPERTY(Category = "Camera|Spline")
	bool bSplineCameraUseSplineDirection = true;

    UPROPERTY(Category = "Camera|Spline")
	float SplineCameraDirectionLead = 0;
	
    UPROPERTY(Category = "Camera|Spline")
	float SplineCameraLookLeadAmount = 8000;

    UPROPERTY(Category = "Camera|Spline")
	bool bSplineCameraAllowInput = true;

    UPROPERTY(Category = "Camera|Spline")
	float SplineCameraInputDelay = 1.0;

	UPROPERTY(Category = "Camera|Spline")
	float SplineCameraInputPitch = 20;

	UPROPERTY(Category = "Camera|Spline")
	float SplineCameraInputYaw = 30;

	UPROPERTY(Category = "Camera|Underwater")
	float UnderwaterCameraLocationDistance = 1000;

	// Steering

	UPROPERTY(Category = "Steering")
	EJetskiSteeringMode SteeringMode = EJetskiSteeringMode::Rotate;

	UPROPERTY(Category = "Steering")
    float SteerMinSpeed = 7000;

	UPROPERTY(Category = "Steering")
    float SteerMaxSpeed = 7000;

    UPROPERTY(Category = "Steering")
    float SlowMaxSteeringAmount = 75;

	UPROPERTY(Category = "Steering")
    float FastMaxSteeringAmount = 75;

    UPROPERTY(Category = "Steering")
    float SteeringDuration = 0.5;

    UPROPERTY(Category = "Steering")
    float SteeringReturnDuration = 0.1;

	UPROPERTY(Category = "Steering|Spline")
	bool bSplineClamp = true;

	UPROPERTY(Category = "Steering|Spline")
	float SplineClampOuterMarginPercentage = 0.95;

	UPROPERTY(Category = "Steering|Spline")
	float SplineClampInnerMarginPercentage = 0.6;

	UPROPERTY(Category = "Steering|Bias")
    float SteeringBiasTimeToReachFullTurnSeconds = 2;

	UPROPERTY(Category = "Steering|Bias")
    float SteeringBiasAmount = 50;


	// Throttle
	
	UPROPERTY(Category = "Throttle")
    float IdleThrottle = 0.0;

	UPROPERTY(Category = "Throttle")
    float ThrottleFromSteering = 0.1;

	UPROPERTY(Category = "Throttle")
    float ThrottleFromDiving = 1.0;

	// When the level starts (or after respawns), how long should we auto hold the throttle?
	UPROPERTY(Category = "Throttle")
    float InitialHoldThrottleDuration = 2.0;

	// How much throttle to apply while auto holding the throttle at the start
	UPROPERTY(Category = "Throttle")
    float InitialHoldThrottle = 0.7;

	// Buoyancy

	UPROPERTY(Category = "Buoyancy")
	float BuoyancyForce = 2000;

	
	// Bobbing

	UPROPERTY(Category = "Bobbing|Pitch")
	float BobbingMaxPitch = 60;

	UPROPERTY(Category = "Bobbing|Pitch")
	float BobbingMinimumVerticalSpeedForImpactImpulse = 400;

	UPROPERTY(Category = "Bobbing|Pitch")
	float BobbingWaterImpactPitch = 0.0001;

	UPROPERTY(Category = "Bobbing|Pitch")
	float BobbingWaterImpactPitchMaxVelocity = 300;

	UPROPERTY(Category = "Bobbing|Pitch")
	float BobbingWaterPitchAirDuration = 2;

	UPROPERTY(Category = "Bobbing|Pitch")
	float BobbingWaterPitchJerk = 0.003;

	UPROPERTY(Category = "Bobbing|Pitch")
	float BobbingWaterPitchJerkStiffness = 100;

	UPROPERTY(Category = "Bobbing|Pitch")
	float BobbingWaterPitchJerkDamping = 0.2;

	UPROPERTY(Category = "Bobbing|Pitch|Diving")
	float BobbingWaterDivingPitch = 2;

	UPROPERTY(Category = "Bobbing|Pitch|Diving")
	float BobbingWaterDivingPitchDuration = 1;

	UPROPERTY(Category = "Bobbing|Pitch|Jumping")
	float BobbingMaxPitchJump = 0; // old value: 50;


	UPROPERTY(Category = "Bobbing|Roll")
	float BobbingMaxRoll = 70;

	UPROPERTY(Category = "Bobbing|Roll")
	float BobbingWaterImpactRoll = 0.001;

	UPROPERTY(Category = "Bobbing|Roll")
	float BobbingWaterImpactRollMaxVelocity = 300;

	UPROPERTY(Category = "Bobbing|Roll")
	float BobbingWaterSteeringRoll = -0.3;

	UPROPERTY(Category = "Bobbing|Roll")
	float BobbingWaterSteeringRollStiffness = 40;

	UPROPERTY(Category = "Bobbing|Roll")
	float BobbingWaterSteeringRollDamping = 0.4;

	UPROPERTY(Category = "Bobbing|Roll")
	float BobbingGroundSteeringRollDuration = 0.5;


	UPROPERTY(Category = "Bobbing|Underwater|Pitch")
	float BobbingUnderwaterMaxPitch = 40;

	UPROPERTY(Category = "Bobbing|Underwater|Yaw")
	float BobbingUnderwaterMaxYaw = 50;

	UPROPERTY(Category = "Bobbing|Underwater|Roll")
	float BobbingUnderwaterWaterSteeringPitch = 0.05;

	UPROPERTY(Category = "Bobbing|Reflect")
	float BobbingReflectImpulseMultiplier = 1.0;

	UPROPERTY(Category = "Bobbing|Reflect")
	float BobbingReflectRotationOffsetDecreaseFactor = 5.0;

	UPROPERTY(Category = "Bobbing|Reflect|Camera Impulse")
	bool bBobbingReflectApplyCameraImpulse = true;

	UPROPERTY(Category = "Bobbing|Reflect|Camera Impulse")
	float BobbingReflectCameraImpulseMultiplier = 0.5;

	UPROPERTY(Category = "Bobbing|Reflect|Camera Impulse")
	float BobbingReflectCameraAngularImpulseMultiplier = 1.0;

	UPROPERTY(Category = "Bobbing|Reflect|Camera Impulse")
	float BobbingReflectCameraImpulseDampening = 0.4;

	UPROPERTY(Category = "Bobbing|Reflect|Camera Impulse")
	float BobbingReflectCameraImpulseExpirationForce = 90.0;


	// Rubber Banding

	UPROPERTY(Category = "Rubber Banding")
	float MinRubberBandDistance = 1000;

	UPROPERTY(Category = "Rubber Banding")
	float MaxRubberBandDistance = 5000;

	UPROPERTY(Category = "Rubber Banding")
	float RubberBandSpeedUpMultiplier = 1.3;

	UPROPERTY(Category = "Rubber Banding")
	float RubberBandSlowDownMultiplier = 0.8;


	// Death

	UPROPERTY(Category = "Death")
	float MinForwardSpeedToDie = 100;

	// At what angle from the impact normal are we going to die at, compared to the Jetski forward direction
	UPROPERTY(Category = "Death", meta = (ClampMin = "0.0", ClampMax = "89.0"))
	float WallImpactDeathJetskiAngleMax = 30.0;

	// At what angle from the impact normal are we going to die at, compared to the Spline direction
	UPROPERTY(Category = "Death", meta = (ClampMin = "0.0", ClampMax = "89.0"))
	float WallImpactDeathSplineAngleMax = 30.0;

	// At what angle from the impact normal are we going to die at
	UPROPERTY(Category = "Death", meta = (ClampMin = "0.0", ClampMax = "89.0"))
	float CeilingImpactDeathAngleMax = 30.0;

	// How far one can player lag behind the other until it's forced to die
	UPROPERTY(Category = "Death")
	float MaxLagDistanceUntilDeath = 8000;


	// Wake

	UPROPERTY(Category = "Wake")
	float WakeStrength = -3000;

	UPROPERTY(Category = "Wake")
	float WakeMaxIntensityDepth = 1000; //If the water beneath the jetski is this many units or deeper, the wake will play at max intensity, otherwise multiplied by the current % of this depth. (Larger number = less intense wakes in shallow water)

	UPROPERTY(Category = "Wake")
	UCurveFloat WakeIntensityOverSpeedAlphaCurve;
}

namespace Jetski
{
	const float Radius = 60;
}