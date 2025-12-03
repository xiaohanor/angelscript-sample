namespace DarkProjectile
{
	namespace Tags
	{
		const FName DarkProjectile = n"DarkProjectile";
		const FName DarkProjectileAim = n"DarkProjectileAim";
		const FName DarkProjectileCharge = n"DarkProjectileCharge";
		const FName DarkProjectileLaunch = n"DarkProjectileLaunch";
	}

	// Range of the player's aim when tracing, also used for auto-aim component distance.
	const float AimRange = 3000.0;

	// Number of projectiles we have when fully charged.
	const int NumProjectiles = 3;

	// Radius used when sweeping projectile movement.
	const float CollisionRadius = 20.0;

	// Time between spawning projectiles while charging.
	const float SpawnInterval = 0.6;

	// Time between launching projectiles.
	const float LaunchInterval = 0.2;
}