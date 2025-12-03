class USkylineSniperTurretSettings : UHazeComposableSettings
{
	// How long should we be aiming before deciding where to shoot
	UPROPERTY()
	float AimDuration = 1.0;

	// How long do we freeze on the decided shoot position before pulling the trigger?
	UPROPERTY()
	float AimFreezeDuration = 0.15;

	UPROPERTY()
	float AimFreezeDurationMultiplierDistance = 10000;

	// How long do we wait before starting to aim again
	UPROPERTY()
	float AimCooldown = 2.0;

	// The projectile lingers this long after hitting
	UPROPERTY()
	float ProjectileHitLinger = 0.5;

	UPROPERTY()
	float ProjectileLaunchSpeed = 20000.0;

	UPROPERTY()
	float ProjectileLaunchSpeedMultiplierDistance = 10000;

	UPROPERTY()
	float AttackRange = 12000;
}