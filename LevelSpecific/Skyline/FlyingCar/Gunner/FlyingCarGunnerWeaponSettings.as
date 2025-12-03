
class UFlyingCarGunnerRifleSettings : UHazeComposableSettings
{
	// Damage per round
	UPROPERTY()
	FHazeRange Damage(0.05, 0.1);

	UPROPERTY()
	float Range = 30000.0;

	// How many rounds per clip
	UPROPERTY()
	int ClipSize = 40;

	UPROPERTY()
	float ReloadTime = 0.8;

	// Rounds per second
	UPROPERTY()
	float RateOfFire = 20.0;

	// Higher value -> less accuracy
	UPROPERTY()
	float Spread = 0.023;

	// [VFX] Round travel time to target
	UPROPERTY()
	FHazeRange BulletTravelTime(0.1, 0.2);
}

class UFlyingCarGunnerBazookaSettings : UHazeComposableSettings
{
	// How much faster than car's velocity rocket will move;
	// missile will start at min and accelerate to max
	UPROPERTY()
	FHazeRange AdditiveMoveSpeed(3000, 8000);

	UPROPERTY()
	float MinToMaxSpeedAccelerationDuration = 0.5;

	UPROPERTY()
	float ReloadTime = 0.8;

	UPROPERTY()
	float Damage = 1.0;

	UPROPERTY()
	float LockOnDuration = 0.7;
}

// DEPRECATED
class UFlyingCarGunnerWeaponSettings : UHazeComposableSettings
{
	// Starting cooldown
	UPROPERTY()
	float CooldownMax = 0.12;

	// Windup min cooldown
	UPROPERTY()
	float CooldownMin = 0.08;

	// How long it takes to reach the min cooldown
	UPROPERTY()
	float TimeToMinCooldown = 2.0;
}