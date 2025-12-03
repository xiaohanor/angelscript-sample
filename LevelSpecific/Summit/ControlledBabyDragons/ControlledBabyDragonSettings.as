namespace ControlledBabyDragon
{
	// Stick input below this will use the minimum speed
	const float MinimumInput = 0.4;
	// Minimum movement speed
	const float MinMoveSpeed = 100.0;
	// Maximum movement speed
	const float MaxMoveSpeed = 300.0;
	// Sprint minimum movement speed
	const float SprintMinMoveSpeed = 300.0;
	// Sprint maximum movement speed
	const float SprintMaxMoveSpeed = 425.0;
	// Acceleration when we want to move faster
	const float MovementAcceleration = 1000.0;
	// Deceleration when we want to move slower
	const float MovementDeceleration = 1000.0;
	// Speed that the dragon rotates to face the input
	const float FacingDirectionInterpSpeed = 5.0;

	const float AirHorizontalMinMoveSpeed = 425.0;
	const float AirHorizontalMaxMoveSpeed = 425.0;
	const float AirMovementRotationSpeed = 1000.0;
	const float AirHorizontalVelocityAcceleration = 1000.0;

	const float JumpImpulse = 650.0;

	const float DashDuration = 0.3;
	const float DashSpeed = 1000.0;
	const float DashCooldown = 0.3;
};