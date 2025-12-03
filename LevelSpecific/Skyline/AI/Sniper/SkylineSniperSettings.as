class USkylineSniperSettings : UHazeComposableSettings
{
	// How long should we be aiming before deciding where to shoot
	UPROPERTY()
	float AimDuration = 2.0;

	// How long do we freeze on the decided shoot position before pulling the trigger?
	UPROPERTY()
	float AimFreezeDuration = 0.05;

	// How long do we wait before starting to aim again
	UPROPERTY()
	float AimCooldown = 3.0;

	// The projectile lingers this long after hitting
	UPROPERTY()
	float ProjectileHitLinger = 0.5;
}