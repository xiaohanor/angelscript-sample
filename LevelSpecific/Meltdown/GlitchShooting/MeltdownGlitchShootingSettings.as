enum EMeltdownGlitchProjectileType
{
	Bullet,
	TwinBullet,
	HomingBullet,
	Rocket,
	Missile,
}

class UMeltdownGlitchShootingSettings : UHazeComposableSettings
{
	/** How long it takes to charge before starting to shoot. */
	UPROPERTY()
	float ChargeDuration = 0.0;

	/** How often we shoot projectiles after charging. */
	UPROPERTY()
	float FireInterval = 0.1;

	/** How long the cooldown is after shooting before we can fire again. */
	UPROPERTY()
	float ChargeCooldown = 0.0;
	
	/** If we haven't tapped the button for this long, stop firing. */
	UPROPERTY()
	float RequiredTapInterval = 0.5;

	/** Movement speed multiplier while actively firing. */
	UPROPERTY()
	float MovementSpeedWhileFiring = 0.5;

	/** How far to trace to find the aiming location. */
	UPROPERTY()
	float AimMaxTraceLength = 20000.0;

	/** Which socket on the player mesh to spawn projectiles at. */
	UPROPERTY()
	FName ProjectileSpawnSocket = n"RightAttach";
	
	/** Offset from thet spawn socket to spawn projectiles at */
	UPROPERTY()
	FVector ProjectileSpawnOffset = FVector(120, 0, -20);

	// How fast the glitch projectile is going when shot
	UPROPERTY()
	float ProjectileInitialSpeed = 30000;

	// How much the projectile accelerates
	UPROPERTY()
	float ProjectileAcceleration = 20000;

	// The max speed the projectile can reach
	UPROPERTY()
	float ProjectileMaxSpeed = 30000;

	// Spread cone angle when firing in degrees
	UPROPERTY()
	float FiringSpreadConeAngle = 5;
	
	// How many projectiles to fire at once
	UPROPERTY()
	int ProjectileCount = 1;

	// How much damage a projectile deals
	UPROPERTY()
	float ProjectileDamage = 1;

	// Type of projectile to fire
	UPROPERTY()
	EMeltdownGlitchProjectileType ProjectileType = EMeltdownGlitchProjectileType::Bullet;

	// Knockback impulse to apply when the player is currently flying
	UPROPERTY()
	float FlyingKnockbackImpulse = 0;
}

asset MeltdownGlitchShootingTwinBulletSettings of UMeltdownGlitchShootingSettings
{
	ProjectileType = EMeltdownGlitchProjectileType::TwinBullet;
	ProjectileCount = 2;
};

asset MeltdownGlitchShootingHomingBulletSettings of UMeltdownGlitchShootingSettings
{
	ProjectileType = EMeltdownGlitchProjectileType::HomingBullet;
	ProjectileCount = 2;
};

asset MeltdownGlitchShootingRocketLauncherSettings of UMeltdownGlitchShootingSettings
{
	ProjectileType = EMeltdownGlitchProjectileType::Rocket;
	FireInterval = 1.0;
	ProjectileDamage = 10.0;
};

asset MeltdownGlitchShootingMissileSettings of UMeltdownGlitchShootingSettings
{
	FireInterval = 0.37;
	ChargeCooldown = 0;
	ProjectileCount = 7;
	ProjectileDamage = 1.0;
	ProjectileInitialSpeed = 2000;
	ProjectileAcceleration = 4000;
	FlyingKnockbackImpulse = 5000;
	ProjectileType = EMeltdownGlitchProjectileType::Missile;
};