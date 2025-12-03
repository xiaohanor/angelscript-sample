class UWingsuitBossSettings : UHazeComposableSettings
{
	// Number of projectile in each attack salvo
	UPROPERTY(Category = "Attack")
	int NumberOfProjectilesPerPlayer = 3; 

	// How far ahead in time we predict player's movement velocity
	UPROPERTY(Category = "Attack")
	float ProjectilePredictionTime = 3.0;

	// When players are more than this far apart along train, we attack both players. Otherwise we only attack foremost.
	UPROPERTY(Category = "Attack")
	float AttackBothPlayersThreshold = 500.0;

	UPROPERTY(Category = "Attack")
	float DriveRearmostPlayerForwardThreshold = 1500.0;

	UPROPERTY(Category = "Attack")
	float DriveRearmostPlayerForwardOffset = 0.0;

	// How far in front of player first projectile id offset (regardless of movement prediction)
	UPROPERTY(Category = "Attack")
	float SpaceBeforeFirstProjectile = 0.0;

	// Space in between each main projectile
	UPROPERTY(Category = "Attack")
	float SpaceBetweenProjectiles = 1250.0;

	// Interval in between firing each main projectile (which then will split into a number of submunitions)
	UPROPERTY(Category = "Attack")
	float TimeBetweenProjectiles = 0.85;

	UPROPERTY(Category = "Attack")
	float InitialLaunchDelay = 0.5;

	UPROPERTY(Category = "Attack")
	float AttackCooldown = 5.0;

	UPROPERTY(Category = "Attack")
	float LauncherAttackPitch = 30.0;


	UPROPERTY(Category = "Attack")
	float ProjectileFlightDuration = 2.0;

	UPROPERTY(Category = "Attack")
	float ProjectileTrajectoryHeight = 1250.0;

	UPROPERTY(Category = "Attack")
	float ProjectileTrajectoryWidth = 1000.0;

	// Length of explosion area
	UPROPERTY(Category = "Attack")
	float ProjectileExplosionLength = 200.0;

	// How fast the player is launched by the projectile
	UPROPERTY(Category = "Attack")
	FVector ProjectileLaunchForce = FVector(-1100.0, 1500.0, 600.0);
	// How long the player is launched by the projectile
	UPROPERTY(Category = "Attack")
	float ProjectileLaunchForceDuration = 0.5;
	// How long the player 'floats' after the projectile's launch finishes
	UPROPERTY(Category = "Attack")
	float ProjectileLaunchFloatDuration = 1.0;
	// How long the point of interest back to the train cart lasts after being hit
	UPROPERTY(Category = "Attack")
	float ProjectileLaunchPointOfInterestDuration = 1.0;
	// Damage to player from projectile
	UPROPERTY(Category = "Attack")
	float ProjectileDamage = 0.9;

	// How many cluster parts the projectile splits into (to hit broadly over the indicated area)
	UPROPERTY(Category = "Attack")
	int ProjectileSubmunitionNumber = 5;

	// When are submunitions deployed (fraction of travel duration)
	UPROPERTY(Category = "Attack")
	float ProjectileSubmunitionDeployFraction = 0.1;

	// Submunitions will be spread over this width, centered on middle of cart
	UPROPERTY(Category = "Attack")
	float ProjectileSubmunitionSpread = 1000.0;

	// How far each submunition lag behind the one before, on average	
	UPROPERTY(Category = "Attack")
	float ProjectileSubmunitionLagInterval = 150.0;

	UPROPERTY(Category = "Attack")
	float ProjectileSubmunitionPitchSpread = 5.0;

	UPROPERTY(Category = "Attack")
	float RepsitionCooldownAfterAttack = 4.0;


	UPROPERTY(Category = "StationKeeping")
	float StationKeepingRange = 1000.0;

	UPROPERTY(Category = "StationKeeping")
	FVector StationKeepingOffsetMin = FVector(9000.0 * 0.7, -3000.0, 1000.0); 

	UPROPERTY(Category = "StationKeeping")
	FVector StationKeepingOffsetMax = FVector(12000.0 * 0.7, 3000.0, 2000.0);

	UPROPERTY(Category = "StationKeeping")
	float InitialRepositionDelay = 0.5;

	UPROPERTY(Category = "StationKeeping")
	float RepositionInterval = 4.0;

	UPROPERTY(Category = "StationKeeping")
	float StationKeepingMoveSpringStiffness = 4.0;

	UPROPERTY(Category = "StationKeeping")
	float StationKeepingMoveSpringDamping = 0.8;

	UPROPERTY(Category = "StationKeeping")
	float StationKeepingRotationSpringStiffness = 2.0;

	UPROPERTY(Category = "StationKeeping")
	float StationKeepingRotationSpringDamping = 0.6;

	UPROPERTY(Category = "StationKeeping")
	bool bKeepStationWithCart = false;

	UPROPERTY(EditAnywhere, Category = "Mines|Turret")
	float ProjectileSpawnCooldown = 0.2;

	UPROPERTY(EditAnywhere, Category = "Mines|Turret")
	float ProjectileSpawnCooldownBetweenBursts = 1.0;

	UPROPERTY(EditAnywhere, Category = "Mines|Turret")
	float ProjectileDurationFromSpawnToShoot = 1.0;

	UPROPERTY(EditAnywhere, Category = "Mines|Projectile")
	float ProjectileDistanceFromPlayerToDetonate = 450.0;

	UPROPERTY(EditAnywhere, Category = "Mines|Projectile")
	float ProjectileGravityAfterShot = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Mines|Projectile")
	float ProjectileShootArcDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Mines|Projectile")
	float ProjectilePlayerDamage = 0.5;

	UPROPERTY(EditAnywhere, Category = "Mines|Projectile")
	float ProjectilePlayerDamageDuration = 0.25;

	UPROPERTY(EditAnywhere, Category = "Mines|Projectile")
	float ProjectileSpringUpToShootPointStiffness = 50.0;

	UPROPERTY(EditAnywhere, Category = "Mines|Projectile")
	float ProjectileSpringUpToShootPointDamping = 0.7;

	UPROPERTY(EditAnywhere, Category = "Mines|Projectile")
	float ProjectileFrontOfPlayerOffset = 4000.0;

	/* How far in front of the player the machine gun should start firing */
	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunPlayerFrontDistance = 8000.0;

	/* How far behind the player the machine gun should stop firing */
	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunPlayerBackDistance = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunPreBurstDelay = 0.5;

	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunBulletCooldown = 0.05;

	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunBurstDuration = 5.0;

	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunPostBurstDelay = 0.5;

	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunDelayBetweenBursts = 1.0;

	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunPredictedPlayerLocationInterpSpeed = 30.0;

	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunMaxSidewaysSinOffset = 250.0;

	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunSidewaysSinFullCycleDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Machine Gun|Projectile")
	float MachineGunTargetTurretSidewaysOffset = 100.0;

	UPROPERTY(EditAnywhere, Category = "Shoot At Target")
	float ShootAtTargetSpawnCooldown = 0.2;

	UPROPERTY(EditAnywhere, Category = "Shoot At Target")
	float ShootAtTargetShootDelay = 0.5;

	UPROPERTY(EditAnywhere, Category = "Shoot At Target")
	float ShootAtTargetOverrideRotationSpringStiffness = 12.0;

	UPROPERTY(EditAnywhere, Category = "Shoot At Target|Projectile")
	float ShootAtTargetProjectileSpeed = 15000.0;

	UPROPERTY(EditAnywhere, Category = "Shoot At Target|Projectile")
	float ShootAtTargetSpiralRotationSpeed = 200;

	UPROPERTY(EditAnywhere, Category = "Shoot At Target|Projectile")
	float ShootAtTargetSpiralRadius = 100.0;
}
