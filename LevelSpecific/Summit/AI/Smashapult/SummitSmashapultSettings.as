class USummitSmashapultSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "SplineEntrance")
	float SplineEntranceMoveSpeed = 1600.0;

	UPROPERTY(Category = "LobProjectile")
	float LobProjectileRange = 10000.0;

	UPROPERTY(Category = "LobProjectile")
	float LobProjectileMaxYaw = 45.0;

	// Projectile is shown after this time playing throw animation
	UPROPERTY(Category = "LobProjectile")
	float LobProjectilePrimeDelay = 0.85;

	// Projectile is launched after this time playing throw animation
	UPROPERTY(Category = "LobProjectile")
	float LobProjectileLaunchDelay = 2.0;

	// Aim projectile to land where player will be in this many seconds
	UPROPERTY(Category = "LobProjectile")
	float LobProjectileLeadTime = 1.0;

	// Time from when a projectile exploded until next projectile is launched.
	UPROPERTY(Category = "LobProjectile")
	float LobProjectileInterval = 2.0;

	// Number of glob projectiles allowed at the same time among all smashapults
	UPROPERTY(Category = "LobProjectile")
	int LobProjectileGlobalAllowance = 1;

	// Projectile trajectory will reach this height before falling down on target
	UPROPERTY(Category = "Projectile")
	float ProjectileTrajectoryHeight = 800.0;

	// Higher value means projectile will be thrown in a higher arc (and will fall faster)
	UPROPERTY(Category = "Projectile")
	float ProjectileGravity = 982.0 * 6.0;

	// Projectile will detonate when near player or this long after landing (also detonates when far below target)
	UPROPERTY(Category = "Projectile")
	float ProjectileExplodeTime = 4.0;

	UPROPERTY(Category = "Projectile")
	float ProjectileBlastRadius = 1400.0;

	UPROPERTY(Category = "Projectile")
	float ProjectileDetonationFraction = 0.8;

	UPROPERTY(Category = "Projectile")
	float ProjectileBlastPushForce = 5000.0;

	UPROPERTY(Category = "Projectile")
	float ProjectileDamage = 0.5;

	UPROPERTY(Category = "Health")
	float DamageFromAcidFactor = 0.25;
}