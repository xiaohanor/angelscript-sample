
namespace BabyDragonTailClimb
{
	// Default maximum range to be able to grab a point with the tail
	const float GrabPointRange = 800.0;
	// Default range for seeing dots for grab points
	const float PointVisibleRange = 1000.0;

	// How long we stay grounded during a grounded enter before we lift off the ground
	const float GroundedEnterSetupTime = 4.0 / 30.0;
	// Speed to move on the ground while during the enter setup time
	const float GroundedEnterSetupSpeed = 400.0;
	// Speed to move toward the climb point after setup is done
	const float GroundedEnterJumpedSpeed = 1600.0;
	// Acceleration at which we achieve the enter speed
	const float EnterSpeedAcceleration = 2000.0;

	// How long we 'hover' while the tail extends to the climb point
	const float AirborneEnterSetupTime = 16.0 / 30.0;
	// How fast we hover toward the climb point while the tail is still extending
	const float AirborneEnterSetupSpeed = 50.0;
	// Speed to move toward the climb point after airborn enter setup is complete
	const float AirborneEnterJumpedSpeed = 1700.0;

	// Vertical speed when jumping off a climb point 
	const float JumpOffVerticalSpeed = 500.0;
	// Horizontal speed away from the wal when jumping off a climb point
	const float JumpOffHorizontalSpeed = 700.0;

	// How long we have to be trying to move to a new point to climb there
	const float ClimbTransferWindUpDuration = 0.5;
	// How fast we move between points when transfering
	const float ClimbTransferSpeed = 1800.0;
	// How fast we accelerate between points when transfering
	const float ClimbTransferAccelerationDuration = 1.0;
	// How far from the wall we jump when transfering
	const float ClimbTransferOutwardDistance = 100.0;
	// How long we have to wait after transfering before we can transfer again
	const float ClimbTransferCooldown = 0.4;
	// The maximum difference in angle between the input we're holding / camera and the direction to the point to allow climbing
	const float ClimbAllowTransferMaximumAngle = 90.0;
};