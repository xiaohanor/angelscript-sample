enum EGravityBikeFreeAccelerationMode
{
	AccelerationBased,
};

enum EGravityBikeFreeFallCameraMode
{
	FaceVelocity,
	FaceVelocityDown,
	AlwaysLookDown,
};

namespace GravityBikeFree
{
    const float GravityFactor = 5000;
};

class UGravityBikeFreeSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "General")
    float AlignmentMaxAngle = 70;

    // Forward
    UPROPERTY(Category = "Forward")
    float MaxSpeed = 4800; // 5000.0

    UPROPERTY(Category = "Forward")
    float MaxSpeedMultiplier = 1.0;

	// Even when boosting, never go past this speed
	UPROPERTY(Category = "Forward")
    float MaxSpeedLimit = 8000; // 8000.0

    UPROPERTY(Category = "Forward")
    float MinimumSpeed = 800;

    UPROPERTY(Category = "Forward|Drag Based")
    float ForwardDragFactor = 5;

    UPROPERTY(Category = "Forward|Drag Based")
    float ForwardNoThrottleDragFactor = 1.5;

    UPROPERTY(Category = "Forward|Drag Based")
    float ForwardReboundMultiplier = 5;

    UPROPERTY(Category = "Forward|Drag Based")
    float SideDragFactor = 10.0;

    UPROPERTY(Category = "Forward|Acceleration Based")
    float Acceleration = 5000;
	
    UPROPERTY(Category = "Forward|Acceleration Based")
    float Deceleration = 2000;

	UPROPERTY(Category = "Forward|Acceleration Based")
	float SideSpeedDeceleration = 4;

    // Steering
    UPROPERTY(Category = "Steering")
	float SteeringMultiplier = 1.0;

    UPROPERTY(Category = "Steering")
    float FastMaxSteeringAngleDeg = 100; // 100.0

    UPROPERTY(Category = "Steering")
    float SlowMaxSteeringAngleDeg = 120; // 120.0

    UPROPERTY(Category = "Steering")
    float FastSpeedThreshold = 3000;

    UPROPERTY(Category = "Steering")
    float SlowSpeedThreshold = 1000;

    UPROPERTY(Category = "Steering")
    float SteeringDuration = 1;

    UPROPERTY(Category = "Steering")
    float SteeringReturnDuration = 0.2;

    // Air
	
    UPROPERTY(Category = "Air")
    float BecomeAirborneDelay = 0.2;

    UPROPERTY(Category = "Air|Drag Based")
    float AirForwardDragFactor = 0.25;

    UPROPERTY(Category = "Air|Drag Based")
    float AirSideDragFactor = 1;

	UPROPERTY(Category = "Air|Acceleration Based")
    float AirMaxSpeed = 3000;

	UPROPERTY(Category = "Air|Acceleration Based")
    float AirMinSpeed = 3000;

	UPROPERTY(Category = "Air|Acceleration Based")
    float AirDeceleration = 1;

    UPROPERTY(Category = "Air|Redirect Velocity")
	float AirRedirectVelocityAmount = 2.5; // 0.5

    // Camera

    UPROPERTY(Category = "Camera|Forward")
	float CameraFollowDuration = 0.8;

	UPROPERTY(Category = "Camera|Forward")
	float CameraInputOffsetResetDuration = 1.0;

    UPROPERTY(Category = "Camera|Falling")
	float CameraFallFollowDuration = 3.0;

    UPROPERTY(Category = "Camera|Falling")
	float CameraFallDelay = 0.5;

    UPROPERTY(Category = "Camera")
	EGravityBikeFreeFallCameraMode CameraFallMode = EGravityBikeFreeFallCameraMode::FaceVelocityDown;

    UPROPERTY(Category = "Camera")
    float CameraLeadAmount = 0.3;

    UPROPERTY(Category = "Camera")
	float ThrottleCameraAccelerateDuration = 2;

    UPROPERTY(Category = "Camera")
	float NoThrottleCameraAccelerateDuration = 1;

    UPROPERTY(Category = "Camera")
	float ThrottleDistanceAdditive = -150;

    UPROPERTY(Category = "Camera")
	float ThrottleFOVAdditive = 10;

	UPROPERTY(Category = "Camera")
	float OffsetFromAngularSpeed = 100;

	UPROPERTY(Category = "Camera")
	float OffsetFromAngularSpeedDuration = 1;

	UPROPERTY(Category = "Camera")
	float ForwardOffsetFromSpeed = 500;

	UPROPERTY(Category = "Camera")
	bool bAlignCameraWithGround = false;

	UPROPERTY(Category = "Camera|Input")
	float CameraInputDelay = 0.5;

	UPROPERTY(Category = "Camera|Input")
	bool bFollowBikeRotation = false;

	UPROPERTY(Category = "Camera|Input")
	bool bSpeedUpIfInputtingIntoSteering = false;

	UPROPERTY(Category = "Camera|Input")
	float SpeedUpIfInputtingIntoSteeringMultiplier = 0.5;
	
	UPROPERTY(Category = "Camera|Roll")
	bool bCameraAddRollWhenTurning = true;

	UPROPERTY(Category = "Camera|Roll")
	float CameraRollMultiplier = 0.1;

	UPROPERTY(Category = "Camera|Roll")
	float CameraRollDuration = 2;

	// Duration to reset in any capability where the Camera Roll target is 0, such as in CenterView
	UPROPERTY(Category = "Camera|Roll")
	float CameraRollResetDuration = 1;

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
	float LandingMaximumImpulse = 5000.0;

	UPROPERTY(Category = "Landing Impact")
	float LandingImpulseMultiplier = 0.05;
};

namespace GravityBikeFree::Input
{
	const FName DriftAction = ActionNames::MovementDash;
};

namespace GravityBikeFree::WallImpact
{
	const float WallImpactRotationOffsetDecreaseFactor = 5.0;
}

namespace GravityBikeFree::WallImpactDeath
{
	const bool bDieFromWallImpact = true;

	/**
	 * If the reflection angle is higher than this, we will die.
	 * Valid range: 0 to 90
	 * High values mean we need to drive more straight into the wall
	 */
	const float WallImpactDeathBikeAngleMax = 60;
};

namespace GravityBikeFree::WallAlign
{
	/**
	 * If the angle between the wall normal and bike forward is higher than this, we align with whe wall.
	 * 0 is moving straight into a wall, and 90 is that we are moving along a wall.
	 * < 0 means always align with a wall, and never reflect.
	 * > 90 means we will always reflect.
	 */
	const float WallAlignMinAngleThreshold = 45;

	const float WallAlignImpulseMultiplier = 0.3;

	// How much to rotate the velocity out away from the wall on impact (degrees)
	const float WallAlignRotationOutOffset = 10;

	// How much velocity to keep after the impact
	const float WallAlignVelocityMultiplier = 0.5;

	const float WallAlignRotationOffsetDecreaseFactor = 5.0;

	/**
	 * Input
	 */

	const bool WallAlignBlockInput = true;
	const float WallAlignInputBlockDuration = 0.5;
	const bool WallAlignBlockThrottleInput = true;
	const bool WallAlignBlockSteeringInput = true;

	/**
	 * Camera
	 */

	const bool bWallAlignApplyCameraImpulse = false;

	const float WallAlignCameraImpulseMultiplier = 0.0003;

	const float WallAlignCameraAngularImpulseMultiplier = 0.0003;

	const float WallAlignCameraImpulseDampening = 0.2;

	const float WallAlignCameraImpulseExpirationForce = 90.0;
}