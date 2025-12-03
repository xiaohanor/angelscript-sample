enum EScifiPlayerCopsGunThrowType
{
	// Hold aim and throw on release
	ThrowAfterAimRelease,

	// Throw immediately on aim press
	ThrowOnAimPress,

	// Hold aim and press shoot to throw
	ThrowOnAimHoldShootPress,

	MAX
}


class UScifiPlayerCopsGunSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Weapon")
	ECollisionChannel TraceChannel = ECollisionChannel::WeaponTracePlayer;


	// The speed we start with when we launch the projectile
	UPROPERTY(Category = "Bullet|Movement")
	float BulletInitialSpeed = 1500;

	// How much the projectile accelerates
	UPROPERTY(Category = "Bullet|Movement")
	float BulletSpeedAcceleration = 6000;

	// The max speed the projectile can reach
	UPROPERTY(Category = "Bullet|Movement")
	float BulletSpeedMax = 20000;

	// How long between each projectile until we can shoot again
	UPROPERTY(Category = "Weapon|Shoot")
	float CooldownBetweenBullets = 0.12;
	
	// How much heat will increase with each shot bullet
	UPROPERTY(Category = "Weapon|Heat")
	float HeatIncreasePerBullet = 0.05;

	// At what heat we will overheat
	UPROPERTY(Category = "Weapon|Heat")
	float MaxHeat = 2.0;

	// While shooting the weapons as the turret, we can modify the heat
	UPROPERTY(Category = "Weapon|Heat")
	float TurretHeadModifier = 1.0;

	// If we overheat, how long will it take until we start cooldown
	UPROPERTY(Category = "Weapon|Heat")
	float OverheatCooldownDelayTime = 3.0;

	// If we overheat, how long will it take until we cooldown
	UPROPERTY(Category = "Weapon|Heat")
	float OverheatCooldownTime = 1.0;

	// How fast do we cooldown when not shooting
	UPROPERTY(Category = "Weapon|Heat")
	float HeatCooldownSpeedWhenNotShooting = 1.0;

	/** If we are no longer shooting, and the previous bullets was shot this time ago, we will start the cooldown */
	UPROPERTY(Category = "Weapon|Heat")
	float HeatCooldownDelayTime = 0.2;

	/** How much faster we shoot the when we have heat.
	 * @ Time; The alpha between 0 and 1 where 1 is max heat
	 * @ Value; The multiplier to the 'CooldownBetweenBullets' delay
	 */
	UPROPERTY(Category = "Weapon|Heat")
	FRuntimeFloatCurve HeatCooldownBetweenBulletsModifier;
	default HeatCooldownBetweenBulletsModifier.AddDefaultKey(0.0, 1.0);

	// How long after the input is held, we can start shooting
	UPROPERTY(Category = "Weapon|Shoot")
	float StartShootDelay = 0.05;

	// The min time we have to be in the strafe move so we can't jitter in and out
	UPROPERTY(Category = "Weapon|Shoot")
	float MinAimAnimationTime = 0.25;

	UPROPERTY(Category = "Input")
	EScifiPlayerCopsGunThrowType ThrowInputType = EScifiPlayerCopsGunThrowType::ThrowOnAimPress;

	// If we just throw the weapons out in the world, how far do we throw them
	UPROPERTY(Category = "Weapon|Throw")
	float WeaponThrowDistance = 1500;

	// How far will we be able to find environment to throw at
	UPROPERTY(Category = "Weapon|Throw")
	float ThrowAtEnvironmentDistance = 3000.0;

	/** If true, we can only throw at walls */
	UPROPERTY(Category = "Weapon|Throw")
	bool bOnlyAllowWallEnvironment = true;

	/** How long time the animation has to play the throw */
	UPROPERTY(Category = "Weapon|Throw")
	float ThrowAnimationTime = 0.15;

	/** How long time until we can recall the weapons after throwing them */
	UPROPERTY(Category = "Weapon|Throw")
	float RecallDelayTime = 0.25;

	/**  If we have a max stay at target time, this will reduce that time
	 * with the specified amount with each bullet shot;
	*/
	UPROPERTY(Category = "Weapon|Remain on Target")
	float RemoveStayAtTargetTimeWithEachBulletShot = 0.0;

	/** The max amount of bullets we will shoot before returning
	 * < 0; it will shoot forever until we call it back or the target is dead
	 */
	UPROPERTY(Category = "Weapon|Remain on Target")
	int StayAtTargetWhileShootingMaxBulletCount = -1;

	/**  The max time the weapons will stay at a weapon target. 
	* < 0; it will stay forever 
	* == 0; it will only trigger the impact and return immediately
	*/
	UPROPERTY(Category = "Weapon|Remain on Target")
	float StayAtNoneShootingTargetMaxTime = 3.0;

	/**  The max time the weapons will stay at a wall impact. 
	* < 0; it will stay forever 
	* == 0; it will only trigger the impact and return immediately
	*/
	UPROPERTY(Category = "Weapon|Remain on Target")
	float StayAtWallImpactMaxTime = -1.0;

	/** The distance we can move away from the guns until they auto recal
	 * Only used if > 0
	 */
	UPROPERTY(Category = "Weapon|Remain on Target", meta = (ClampMin = "0.0"))
	float MaxDistanceFromThrowPositionUntilAutoRecal = -1.0;

	// The speed we start with when we launch the projectile
	UPROPERTY(Category = "Weapon|Movement")
	float WeaponInitialSpeed = 800;

	// How much the projectile accelerates
	UPROPERTY(Category = "Weapon|Movement")
	float WeaponSpeedAcceleration = 6000;

	// The max speed the projectile can reach
	UPROPERTY(Category = "Weapon|Movement")
	float WeaponSpeedMax = 2000;

	// When going back to the player, we can pick another speed
	UPROPERTY(Category = "Weapon|Movement", meta = (ClampMin = "0.0"))
	float TravelBackToPlayerMoveSpeedMultiplier = 1.5;

	// When going back to the player, we can pick another speed
	UPROPERTY(Category = "Weapon|Movement", meta = (ClampMin = "0.0"))
	float TravelBackToPlayerAccelerationMultiplier = 1.5;

	// If true, the camera will apply the aimsettings when shooting, else, we need to hold the aim button
	UPROPERTY(Category = "Player|Camera")
	bool bAutoAimDown = true;

	// If true, the player will go into strafe when we shoot, else, only when we aim
	UPROPERTY(Category = "Player|Movement")
	bool bAlwaysStrafeWhenShooting = true;

	// The min time we have to be in the strafe move so we can't jitter in and out
	UPROPERTY(Category = "Player|Movement")
	float MinStrafeTime = 0.5;

	// How much percentage of the movespeed we should remove while shooting
	UPROPERTY(Category = "Player|Movement", meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float PlayerMoveSpeedReductionWhileShooting = 0.0;
	
	/**  How much percentage of the movespeed we should remove while shooting
	 * this settings makes you move slower the more weapons you shoot
	*/
	UPROPERTY(Category = "Player|Movement", meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float PlayerMoveSpeedReductionWhileShootingPerWeapon = 0.2;

}
