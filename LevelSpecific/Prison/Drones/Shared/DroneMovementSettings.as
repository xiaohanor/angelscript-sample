class UDroneMovementSettings : UHazeComposableSettings 
{
    // Grounded

	UPROPERTY(Category = "Grounded")
	bool bUseGroundStickynessWhileGrounded = false;

	// Force applied when trying to move on the ground
	UPROPERTY(Category = "Grounded")
	float GroundAcceleration = 3750	;

	// How fast we want to decelerate when not on a slope
	UPROPERTY(Category = "Grounded")
	float GroundDeceleration = 1500;

	// Multiplier when we are inputting in a direction different to the current movement
	UPROPERTY(Category = "Grounded")
	float GroundReboundMultiplier = 1;

	// Maximum ground move speed
	UPROPERTY(Category = "Grounded")
	float GroundMaxHorizontalSpeed = 900;

	// Deceleration towards MaxMoveSpeed when we are traveling too fast
	UPROPERTY(Category = "Grounded")
	float GroundMaxSpeedDeceleration = 1000;

	// This attempts to mitigate sliding on very slightly sloped surfaces
	UPROPERTY(Category = "Grounded")
	bool bStopIfOnFlatGroundWithNoHorizontalVelocity = true;

	// Max walkable/jumpable slope
	UPROPERTY(Category = "Grounded|Slope")
	float MaxSlopeAngle = 60;

	// How steep a slope should be to be considered a slope and start rolling
	UPROPERTY(Category = "Grounded|Slope")
	float MinSlopeAngle = 10;

	// At what angle full UpSlopeMultiplier is applied
	UPROPERTY(Category = "Grounded|Slope")
	float MaxInputSlopeAngle = 55;

	// Pow(UpSlopeFactor, UpSlopeExponent) to get a sharper decrease in speed when going up a slope
	UPROPERTY(Category = "Grounded|Slope")
	float UpSlopeExponent = 1;

	// The maximum multiplier applied when going up a slope
	UPROPERTY(Category = "Grounded|Slope")
	float UpSlopeMultiplier = 0.0;

	UPROPERTY(Category = "Grounded|Slope")
	float UpSlopeDeceleration = 1000;

	UPROPERTY(Category = "Grounded|Slope")
	float UpSlopeSideDeceleration = 1000;

	UPROPERTY(Category = "Grounded|Slope")
	float UpSlopeWithInputDeceleration = 0;

	UPROPERTY(Category = "Grounded|Slope")
	float UpSlopeSideWithInputDeceleration = 500;

	UPROPERTY(Category = "Grounded|Slope")
	float DownSlopeDeceleration = 250;

	UPROPERTY(Category = "Grounded|Slope")
	float DownSlopeSideDeceleration = 100;

	UPROPERTY(Category = "Grounded|Edges")
	bool bUnstableOnEdges = true;

    // Airborne

	// Target speed in air
	UPROPERTY(Category = "Airborne|Horizontal")
	float AirAcceleration = 1500;
	// Acceleration to target speed in air
	UPROPERTY(Category = "Airborne|Horizontal")
	float AirMaxHorizontalSpeed = 800;
	// Acceleration to target speed in air
	UPROPERTY(Category = "Airborne|Horizontal")
	float AirMaxSpeedDeceleration = 2000;
	// Multiplier when we are inputting in a direction different to the current movement
	UPROPERTY(Category = "Airborne|Horizontal")
	float AirReboundMultiplier = 2;

	UPROPERTY(Category = "Airborne|Vertical")
	float AirMaxFallSpeed = -1500;
	UPROPERTY(Category = "Airborne|Vertical")
	float AirMaxFallDeceleration = 3000;

    // Dashing

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

	// Jumping

	// Still used
	UPROPERTY(Category = "Jumping")
	float JumpImpulse = 1100;

	// AKA Coyote Time
	UPROPERTY(Category = "Jumping")
	float JumpGraceTime = 0.2;

	UPROPERTY(Category = "Jumping")
	float JumpInputBufferTime = 0.1;

	UPROPERTY(Category = "Jumping")
	float JumpMaxHorizontalSpeed = 900;

	// Roll
	UPROPERTY(Category = "Roll")
	float RollMaxSpeed = 15;
};

namespace Drone
{
	// Higher values will prevent the ball from getting airborne, but may also make it too sticky
	const float ExtraGroundTraceDistance = 1;
	const float Gravity = 2500.0;
};