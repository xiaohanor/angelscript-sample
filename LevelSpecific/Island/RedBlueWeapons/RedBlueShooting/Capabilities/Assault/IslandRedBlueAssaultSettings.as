class UIslandRedBlueAssaultSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Shooting")
	float RumbleAmount = 0.5;

	UPROPERTY(Category = "Bullet")
	float BulletInitialSpeed = 9000;

	// How much the projectile accelerates
	UPROPERTY(Category = "Bullet")
	float BulletSpeedAcceleration = 6000;

	// The max speed the projectile can reach
	UPROPERTY(Category = "Bullet")
	float BulletSpeedMax = 25000;

	UPROPERTY(Category = "Bullet")
	float StartCoolDownBetweenBullets = 0.03;

	// How long between each projectile until we can shoot again
	UPROPERTY(Category = "Bullet")
	float TargetCoolDownBetweenBullets = 0.06;

	// How the interpolation between min/max cooldown between bullets is defined. y: 0 is min cooldown, y: 1 is max cooldown, x: 0 is when you start shooting, x: 1 is when you have been shooting for CoolDownBetweenBulletsCurveDuration seconds
	UPROPERTY(Category = "Bullet")
	FRuntimeFloatCurve CoolDownBetweenBulletsCurve;
	default CoolDownBetweenBulletsCurve.AddDefaultKey(0.0, 0.0);
	default CoolDownBetweenBulletsCurve.AddDefaultKey(1.0, 1.0);

	/* How long it will take to go from x: 0 to x:1 on CoolDownBetweenBulletsCurve (starts when you start shooting) */
	UPROPERTY(Category = "Bullet")
	float CoolDownBetweenBulletsCurveDuration = 0.5;

	UPROPERTY(Category = "Bullet")
	float BulletDamageMultiplier = 1.0;
}