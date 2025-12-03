namespace LightProjectile
{
	namespace Tags
	{
		const FName LightProjectile = n"LightProjectile";
		const FName LightProjectileAim = n"LightProjectileAim";
		const FName LightProjectileCharge = n"LightProjectileCharge";
		const FName LightProjectileLaunch = n"LightProjectileLaunch";
	}

	namespace Wings
	{
		// Length of the wing, distance from spine socket location.
		const float Length = 50.0;

		// Lengthens or shortens the wing increasingly with each instance.
		const float LengthStep = 6.0;

		// Angular offset from base rotation.
		const float AngularOffset = 50.0;

		// Angular offset in degrees between each projectile.
		const float AngularStep = 18.0;

		// Changes the speed of the drift.
		const float DriftFrequency = 1.0;
		
		// Effectively the angular distance in degrees we drift from our resting point.
		const float DriftMagnitude = 10.0;
	}

	// Range of the player's aim when tracing, also used for auto-aim component distance.
	const float AimRange = 3000.0;

	// Number of projectiles we have when fully charged.
	const int NumProjectiles = 12;

	// Radius used when sweeping projectile movement.
	const float CollisionRadius = 20.0;
	
	// Time between spawning projectiles while charging.
	const float SpawnInterval = 0.6;

	// Time between launching projectiles.
	const float LaunchInterval = 0.0;

	// Name of the socket/bone used as the origin transform for the light wings.
	const FName SpineSocketName = n"Spine2";
}