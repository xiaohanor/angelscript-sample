class UPinballMovementSettings : UHazeComposableSettings
{
	/**
	 * Ground
	 */

	// Force applied when trying to move on the ground
	UPROPERTY(Category = "Ground")
	float MoveForce = 5000;

	// Maximum ground move speed
	UPROPERTY(Category = "Ground")
	float MaxSpeed = 800;
	
	// Apply deceleration if we are above this speed
	UPROPERTY(Category = "Ground")
	float MinimumSpeedToDecelerate = 0;

	// How fast we want to decelerate when not on a slope
	UPROPERTY(Category = "Ground")
	float DecelerateSpeed = 1500;

	// Multiplier when we are inputting in a direction different to the current movement
	UPROPERTY(Category = "Ground")
	float ReboundMultiplier = 1.2;

	// Deceleration towards MaxMoveSpeed when we are travelling too fast
	UPROPERTY(Category = "Ground")
	float MaxSpeedDeceleration = 1000;

	/**
	 * Slope
	 */

	// How steep a slope should be to be considered a slope and start rolling
	UPROPERTY(Category = "Slope")
	float MinSlopeAngle = 10;

	// At what angle full UpSlopeMultiplier is applied
	UPROPERTY(Category = "Slope")
	float MaxInputSlopeAngle = 50;

	// Pow(UpSlopeFactor, UpSlopeExponent) to get a sharper decrease in speed when going up a slope
	UPROPERTY(Category = "Slope")
	float UpSlopeExponent = 3;

	// The maximum multiplier applied when going up a slope
	UPROPERTY(Category = "Slope")
	float UpSlopeMultiplier = 0.001;
	
	// Do we want to decelerate when on slopes?
	UPROPERTY(Category = "Slope")
	bool bDecelerateOnSlopes = true;

	// How fast we want to decelerate when on a slope
	UPROPERTY(Category = "Slope")
	float SlopeDecelerateSpeed = 0.1;

	/**
	 * Air
	 */

	// Target speed in air
	UPROPERTY(Category = "Air|Horizontal")
	float AirMoveForce = 1250;

	// Acceleration to target speed in air
	UPROPERTY(Category = "Air|Horizontal")
	float AirMaxHorizontalSpeed = 750;

	// Acceleration to target speed in air
	UPROPERTY(Category = "Air|Horizontal")
	float AirMaxSpeedDeceleration = 1000;

	// Multiplier when we are inputting in a direction different to the current movement
	UPROPERTY(Category = "Air|Horizontal")
	float AirReboundAccelerationMultiplier = 3;

	// If the vertical speed is lower than this, we allow input
	UPROPERTY(Category = "Air|Horizontal")
	float AirVerticalSpeedHorizontalInputThreshold = 2500;

	UPROPERTY(Category = "Air|Horizontal")
	float TrailMargin = 500;

	UPROPERTY(Category = "Air|Vertical")
	float AirMaxFallSpeed = -1500;

	UPROPERTY(Category = "Air|Vertical")
	float AirFallDeceleration = 3000;

	/**
	 * Dashing
	 */

	UPROPERTY(Category = "Dashing")
	bool bUseGroundStickynessWhileDashing = false;

	UPROPERTY(Category = "Dashing")
	float DashMaximumSpeed = 1000.0;

	UPROPERTY(Category = "Dashing")
	float DashInputBufferWindow = 0.08;

	UPROPERTY(Category = "Dashing")
	float DashCooldown = 0.2;

	UPROPERTY(Category = "Dashing")
	float DashDuration = 0.2;

	UPROPERTY(Category = "Dashing")
	float DashExitSpeed = 700.0;

	UPROPERTY(Category = "Dashing")
	float DashSprintExitBoost = 50.0;

	UPROPERTY(Category = "Dashing")
	float DashEnterSpeed = 1500.0;

	UPROPERTY(Category = "Dashing")
	float DashTurnDuration = 0.75;

	/**
	 * Attraction
	 */

	// How fast we want to go towards the camera when starting attracting
	UPROPERTY(Category = "Attraction")
	float StartExtraBackVelocity = 1000;

	UPROPERTY(Category = "Attraction")
	float AttractionAlphaPow = 2.5;

	UPROPERTY(Category = "Attraction")
	float AttractionSpeed = 3000.0;

	UPROPERTY(Category = "Attraction")
	float AttractionSpringAlphaPow = 1.0;

	UPROPERTY(Category = "Attraction")
	FVector2D SpringStiffness = FVector2D(10, 500);

	UPROPERTY(Category = "Attraction")
	FVector2D SpringDamping = FVector2D(0.1, 1.0);

	UPROPERTY(Category = "Attraction")
	float FinalForwardVelocity = 5000;

	/**
	 * Magnet Movement
	 */

	UPROPERTY(Category = "Magnet")
	float MagnetMaxMoveSpeed = 600;

	UPROPERTY(Category = "Magnet")
	float MagnetMaxMoveSpeedDeceleration = 2000;

	UPROPERTY(Category = "Magnet")
	float MagnetAcceleration = 7000;

	UPROPERTY(Category = "Magnet")
	float MagnetReboundAccelerationMultiplier = 1.5;

	UPROPERTY(Category = "Magnet")
	float MagnetDeceleration = 3000;

	/**
	 * Jump
	 */

	UPROPERTY(Category = "Jump")
	float JumpInputBufferTime = 0.1;

	UPROPERTY(Category = "Jump")
	float JumpGraceTime = 0.2;

	UPROPERTY(Category = "Jump")
	float JumpImpulse = 1300;

	/**
	 * Gravity
	 */

	UPROPERTY(Category = "Gravity")
	float Gravity = 2500;

	/**
	 * Launch
	 */

	UPROPERTY(Category = "Launch")
	bool bApplyDecelerationWhileLaunched = false;

	UPROPERTY(Category = "Launch")
	bool bApplyGravityWhileLaunched = false;

	UPROPERTY(Category = "Launch")
	float LaunchMaxSpeed = 3000;

	UPROPERTY(Category = "Launch")
	float LaunchDeceleration = 5000;
}

namespace Pinball
{
	namespace Movement
	{
		// Max walkable/jumpable slope
		const float MaxSlopeAngle = 60;

		const float RailInterpToSyncPointDuration = 0.2;
	}

	namespace ScalarMovement
	{
		// Resolver

		// Higher values will prevent the ball from getting airborne, but may also make it too sticky
		const float ExtraGroundTraceDistance = 1;

		// Ground Movement

		// Force applied when trying to move on the ground
		const float MoveForce = 5000;

		// Maximum ground move speed
		const float MaxSpeed = 1000;
		// How fast we want to decelerate when not on a slope
		const float DecelerateSpeed = 1500;
		// Multiplier when we are inputting in a direction different to the current movement
		const float ReboundMultiplier = 1.1;
		// Deceleration towards MaxMoveSpeed when we are travelling too fast
		const float MaxSpeedDeceleration = 1000;
		
		// Slope Movement

		// Max walkable/jumpable slope
		const float MaxSlopeAngle = 60;
		// How steep a slope should be to be considered a slope and start rolling
		const float MinSlopeAngle = 10;
		// At what angle full UpSlopeMultiplier is applied
		const float MaxInputSlopeAngle = 55;
		// Pow(UpSlopeFactor, UpSlopeExponent) to get a sharper decrease in speed when going up a slope
		const float UpSlopeExponent = 1.5;
		// The maximum multiplier applied when going up a slope
		const float UpSlopeMultiplier = 0.2;

		// Air Movement

		// Horizontal
		// Target speed in air
		const float AirMoveForce = 1250;
		// Acceleration to target speed in air
		const float AirMaxHorizontalSpeed = 750;
		// Acceleration to target speed in air
		const float AirMaxSpeedDeceleration = 500;
		// Multiplier when we are inputting in a direction different to the current movement
		const float AirReboundAccelerationMultiplier = 2;
		// If the vertical speed is lower than this, we allow input
		const float AirVerticalSpeedHorizontalInputThreshold = 2500;
		const float TrailMargin = 500;

		// Vertical
		const float AirMaxFallSpeed = -1500;
		const float AirFallDeceleration = 1000;

		// Magnet Movement
		const float MagnetMaxMoveSpeed = 600;
		const float MagnetMaxMoveSpeedDeceleration = 2000;
		const float MagnetAcceleration = 7000;
		const float MagnetReboundAccelerationMultiplier = 1.5;
		const float MagnetDeceleration = 3000;

		// Jump
		const float JumpInputBufferTime = 0.1;
		const float JumpGraceTime = 0.2;
		const float JumpImpulse = 1300;

		// Gravity
		const float Gravity = -2500;
	}
}