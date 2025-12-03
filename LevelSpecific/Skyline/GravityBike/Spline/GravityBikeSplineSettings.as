class UGravityBikeSplineSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "General")
	float ForceInputDuration = 3.0;

    UPROPERTY(Category = "General")
    float WalkableSlopeAngle = 50;

    // Forward

    UPROPERTY(Category = "Forward")
    float MaxSpeed = 5000;

    UPROPERTY(Category = "Forward")
    float MinimumSpeed = 1000;

    UPROPERTY(Category = "Forward")
    float ForwardDragFactor = 5;

    UPROPERTY(Category = "Forward")
    float ForwardNoThrottleDragFactor = 1.5;

    UPROPERTY(Category = "Forward")
    float SideDragFactor = 3000.0;

	// Throttle

	UPROPERTY(Category = "Throttle")
	float ThrottleStickTime = 0.5;

	UPROPERTY(Category = "Throttle")
	float ThrottleIncreaseDuration = 0.2;

	UPROPERTY(Category = "Throttle")
	float ThrottleDecreaseDuration = 1;

    // Steering

    UPROPERTY(Category = "Steering")
    float FastMaxSteeringAngleDeg = 45;

    UPROPERTY(Category = "Steering")
    float SlowMaxSteeringAngleDeg = 50;

    UPROPERTY(Category = "Steering")
    float FastSpeedThreshold = 3000;

    UPROPERTY(Category = "Steering")
    float SlowSpeedThreshold = 1000;

    UPROPERTY(Category = "Steering")
    float SteeringDuration = 2;

    UPROPERTY(Category = "Steering")
    float SteeringReturnDuration = 1.5;

    // Air
    UPROPERTY(Category = "Air")
    float BecomeAirborneDelay = 0.1;

    UPROPERTY(Category = "Air")
    float AirForwardDragFactor = 0.25;

    UPROPERTY(Category = "Air")
    float AirSideDragFactor = 2.0;

	UPROPERTY(Category = "Air")
	float AirSteerMultiplier = 0.5;

	UPROPERTY(Category = "Air")
    float AirAccelerateMultiplier = 0.5;

    // Camera

    UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset DriverCamSettings;

    UPROPERTY(Category = "Camera")
	float ThrottleCameraAccelerateDuration = 1;

	UPROPERTY(Category = "Camera")
	float NoThrottleCameraAccelerateDuration = 2;

    UPROPERTY(Category = "Camera")
	float NoThrottleDistanceAdditive = -50;

    UPROPERTY(Category = "Camera")
	float NoThrottleFOVAdditive = -20;

	/**
	 * Landing Impulse
	 */
	
	UPROPERTY(Category = "Landing Impact")
	bool bApplyPitchImpulseOnLanding = true;

	UPROPERTY(Category = "Landing Impact")
	float LandingImpulseMinimumThreshold = 1500.0;

	UPROPERTY(Category = "Landing Impact")
	float LandingMinimumImpulse = 2500.0;

	UPROPERTY(Category = "Landing Impact")
	float LandingMaximumImpulse = 3000.0;

	UPROPERTY(Category = "Landing Impact")
	float LandingImpulseMultiplier = 0.05;

	/**
	 * If the angle between the wall normal and bike forward is higher than this, we align with whe wall.
	 * 0 is moving straight into a wall, and 90 is that we are moving along a wall.
	 * < 0 means always align with a wall, and never reflect.
	 * > 90 means we will always reflect.
	 */
	UPROPERTY(Category = "Wall Align")
	float WallAlignMinAngleThreshold = 45;

	/**
	 * If the angle is higher than this between the wall normal and the spline forward, consider it a
	 * wall we want to slide along, instead of dying when hit
	 */
	UPROPERTY(Category = "Death", meta = (ClampMin = "0.0", ClampMax = "89.0"))
	float WallSlideAngleMin = 70;

	// At what angle from the impact normal are we going to die at compared to the spline direction
	UPROPERTY(Category = "Death", meta = (ClampMin = "0.0", ClampMax = "89.0"))
	float WallImpactDeathSplineAngleMax = 10;

	// At what angle from the impact normal are we going to die at compared to the bike forward
	UPROPERTY(Category = "Death", meta = (ClampMin = "0.0", ClampMax = "89.0"))
	float WallImpactDeathBikeAngleMax = 45;

	// Camera

	UPROPERTY(Category = "Camera")
	float SplineDirectionLead = 0;

	UPROPERTY(Category = "Camera")
	float OffsetFromTurning = 100;
	
	UPROPERTY(Category = "Camera")
	float OffsetFromTurningDuration = 1;

	// Change Gravity

	UPROPERTY(Category = "Change Gravity")
	UCurveFloat ChangeGravityAlphaCurve;

	UPROPERTY(Category = "Change Gravity")
	float ChangeGravityJumpImpulse = 1000;

	// VFX

	UPROPERTY(Category = "VFX")
	bool bUseWaterTrail = true;
};

namespace GravityBikeSpline
{
    const float GravityAmount = 4000;
	const float DefaultFOV = 70;
	const float DefaultIdealDistance = 500;
	const float Radius = 48.0;

	const float AutoAimExponent = 2;
};