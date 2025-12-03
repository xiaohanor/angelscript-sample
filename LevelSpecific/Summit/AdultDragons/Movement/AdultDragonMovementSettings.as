
namespace AdultDragonMovement
{
	// Stick input below this will use the minimum speed
	const float MinimumInput = 0.4;
	// Minimum movespeed in air
	const float AirMinMoveSpeed = 1000.0;
	// Maximum movespeed in air
	const float AirMaxMoveSpeed = 2000.0;
	// Acceleration of movespeed in air
	const float AirAcceleration = 3000.0;
	// Wanted vertical speed when holding A or B to go up or down
	const float VerticalWantedSpeed = 3000.0;
	// Deceleration speed when we release all input
	const float NoInputDeceleration = 9500.0;
	// If we're looking slightly downward, ignore that, we are expecting it to be the neutral
	const float IgnoreLookingDownAngle = -30.0;
};