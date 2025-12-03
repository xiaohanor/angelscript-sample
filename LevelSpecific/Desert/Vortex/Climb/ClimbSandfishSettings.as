namespace ClimbSandFish
{
	const float MaxMoveSpeed = 5000;
	const float MinMoveSpeed = 3000;
	const float AvoidVortexDistance = 8000;
	const float SideSteerDistance = 1500;
	const float SideSteerSpeed = 1500;

	// If true, apply the steering on a velocity, then apply the steering to the side offset.
	// If false, we use the steering directly, causing the fish to reset to the center when no steering is applied
	const bool bUseVelocityWhenSteering = false;
}