class UIslandRedBlueOverheatAssaultSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Shooting")
	float RumbleAmount = 1.0;

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

	/* This amount of alpha will be added to the overheat alpha every shot */
	UPROPERTY(Category = "Overheat")
	float OverheatAmountPerShot = 0.0315;

	/* Alpha per second that is cooled down */
	UPROPERTY(Category = "Overheat")
	float OverheatCooldownSpeed = 2.0;

	/* Max rumble during overheat cooldown (This is multiplied by the alpha so it linearly falls off) */
	UPROPERTY(Category = "Overheat")
	float OverheatRumbleAmount = 0.3;

	/* How long to wait when overheating before actually cooling down */
	UPROPERTY(Category = "Overheat")
	float CooldownBeforeCoolingDown = 0.5;
	
	/* How much to rumble just when reaching overheat, like an impact */
	UPROPERTY(Category = "Overheat")
	float ImpactOverheatRumbleAmount = 1000.0;

	/* How long impact overheat should last */
	UPROPERTY(Category = "Overheat")
	float ImpactOverheatRumbleDuration = 0.2;

	/* Overheat alpha will be multiplied by this value to determine how much FOV to add to the base FOV */
	UPROPERTY(Category = "Overheat")
	float FOVMaxIncrease = -5.0;

	/* Higher value means smoother fov change */
	UPROPERTY(Category = "Overheat")
	float FOVAccelerationDuration = 0.25;
}