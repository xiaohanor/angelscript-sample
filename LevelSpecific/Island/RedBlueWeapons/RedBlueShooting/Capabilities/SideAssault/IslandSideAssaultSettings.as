class UIslandRedBlueSidescrollerAssaultSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Shooting")
	float RumbleAmount = 0.5;

	UPROPERTY(Category = "Spotlight")
	bool bShowSpotlightInSidescroller = true;

	UPROPERTY(Category = "Spotlight")
	bool bShowSpotlightInTopDown = true;

	UPROPERTY(Category = "Spotlight")
	bool bShowSpotlightIn3D = false;

	UPROPERTY(Category = "Spotlight")
	float SpotlightAimAccelerationDuration = 0.0;	

	UPROPERTY(Category = "Spotlight")
	bool bFadeOverShortDistance = true;

	UPROPERTY(Category = "Spotlight", Meta = (EditCondition = "bHasSpotlight && bFadeOverShortDistance", EditConditionHides))
	float SpotlightFadeLength = 500.0;

	UPROPERTY(Category = "Bullet")
	float BulletInitialSpeed = 5000;

	// How much the projectile accelerates
	UPROPERTY(Category = "Bullet")
	float BulletSpeedAcceleration = 3000;

	// The max speed the projectile can reach
	UPROPERTY(Category = "Bullet")
	float BulletSpeedMax = 7500;

	UPROPERTY(Category = "Bullet")
	float StartCoolDownBetweenBullets = 0.033;

	// How long between each projectile until we can shoot again
	UPROPERTY(Category = "Bullet")
	float TargetCoolDownBetweenBullets = StartCoolDownBetweenBullets;

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

	UPROPERTY(Category = "Bullet|Homing")
	bool bUseHomingInSidescroller = true;

	UPROPERTY(Category = "Bullet|Homing")
	bool bUseHomingInTopDown = true;

	UPROPERTY(Category = "Bullet|Homing", Meta = (EditCondition = "bUseHomingInSidescroller || bUseHomingInTopDown", EditConditionHides))
	float HomingInterpSpeed = 10.0;

	UPROPERTY(Category = "Bullet|Homing", Meta = (EditCondition = "bUseHomingInSidescroller || bUseHomingInTopDown", EditConditionHides))
	float HomingInterpSpeedAccelerationDuration = 0.2;

	UPROPERTY(Category = "Bullet|Homing", Meta = (EditCondition = "bUseHomingInSidescroller || bUseHomingInTopDown", EditConditionHides))
	bool bDebugDrawHomingTargets = false;

	UPROPERTY(Category = "Bullet|Homing", Meta = (EditCondition = "bUseHomingInSidescroller || bUseHomingInTopDown", EditConditionHides))
	bool bDisengageHomingAfterPassingTarget = true;

	UPROPERTY(Category = "Bullet|Cone")
	float ConeMaxDegreeOffset = 10.0;

	/* If true the bullets will redirect after a while to make the cone have a maximum width. */
	UPROPERTY(Category = "Bullet|Cone")
	bool bClampMaxConeWidth = true;

	/* Bullets will curve after a while to make sure the cone can't be wider than this */
	UPROPERTY(Category = "Bullet|Cone", Meta = (EditCondition = "bClampMaxConeWidth", EditConditionHides))
	float MaxConeWidth = 200.0;

	/* Bullets will start lerping their shoot direction when this amount of units away from distance. The smoothing will also continue this distance after the initial distance */
	UPROPERTY(Category = "Bullet|Cone", Meta = (EditCondition = "bClampMaxConeWidth", EditConditionHides))
	float MaxConeWidthSmoothingExtents = 500.0;

	UPROPERTY(Category = "Bullet|Cone", Meta = (EditCondition = "bClampMaxConeWidth", EditConditionHides))
	bool bDebugDrawMaxConeWidth = false;
}