class UTrainFlyingEnemySettings : UHazeComposableSettings
{
	// What offset we start at when flying in towards train 
	UPROPERTY(Category = "HoverMovement")
	FVector StartingOffset = FVector(120000.0, 30000.0, 0.0);	

	// How far in front/to the side/above the player to hover the car, 
	// in addition to spline offset from placement in editor. 
	// Randomize between this and max between each attack.
	UPROPERTY(Category = "HoverMovement")
	FVector HoverDistanceOffsetMin = FVector(1500.0, -1000.0, -500.0);

	// How far in front/to the side/above the player to hover the car, 
	// in addition to spline offset from placement in editor. 
	// Randomize between this and min between each attack.
	UPROPERTY(Category = "HoverMovement")
	FVector HoverDistanceOffsetMax = FVector(5000.0, 2000.0, 1000.0);

	// Rotate towards a position along the rail this far ahead of player
	UPROPERTY(Category = "HoverMovement")
 	float HoverRotateTowardsDistanceInFrontOfTarget = 400.0;

	// How long the car takes to reach target location when initially flying in
	UPROPERTY(Category = "HoverMovement")
	float MovementFlyingInDuration = 10.0;

	// How long does the car take to move into a new position
	// This is how fast it moves when it moves, not how often it moves.
	UPROPERTY(Category = "HoverMovement")
	float MovementLocationChangeDuration = 10.0;

	// When initially flying in, we only start attacking when within this distance from target location
	UPROPERTY(Category = "Attack")
	float StartAttackingRange = 3000.0;

	// Settings for the projectiles attack
	UPROPERTY(Category = "Attack")
	int ProjectileAmount = 3;

	// How far ahead in time we prdict player's movement velocity
	UPROPERTY(Category = "Attack")
	float ProjectilePredictionTime = 1.0;

	// How far in front of player first projectile id offset (regardless of movement prediction)
	UPROPERTY(Category = "Attack")
	float SpaceBeforeFirstProjectile = 0.0;

	UPROPERTY(Category = "Attack")
	float SpaceBetweenProjectiles = 1250.0;

	UPROPERTY(Category = "Attack")
	float TimeBetweenProjectiles = 0.35;

	// How long before shooting after moving away
	UPROPERTY(Category = "Attack")
	float TimeWaitBeforeProjectiles = 0.5;

	// How long before moving away, after shooting finished
	UPROPERTY(Category = "Attack")
	float TimeWaitAfterProjectiles = 4.0;


	UPROPERTY(Category = "Attack")
	float ProjectileTravelDuration = 1.5;

	UPROPERTY(Category = "Attack")
	float ProjectileTrajectoryHeight = 750.0;
	
	// Length of explosion area
	UPROPERTY(Category = "Attack")
	float ProjectileExplosionLength = 300.0;

	// How fast the player is launched by the projectile
	UPROPERTY(Category = "Attack")
	FVector ProjectileLaunchForce = FVector(-750.0*1.5, 1000.0*1.5, 400.0*1.5);
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
	float ProjectileDamage = 0.5;

	// How many cluster parts the projectile splits into (to hit broadly over the indicated area)
	UPROPERTY(Category = "Attack")
	int ProjectileSubmunitionNumber = 5;
	// When are submunitions deployed (fraction of travel duration)
	UPROPERTY(Category = "Attack")
	float ProjectileSubmunitionDeployFraction = 0.5;
	// Submunitions will be spread over this width, centered on middle of cart
	UPROPERTY(Category = "Attack")
	float ProjectileSubmunitionSpread = 1000.0;
	// Submunition pitch varies from negative to positive of this value
	UPROPERTY(Category = "Attack")
	float ProjectileSubmunitionPitchSpread = 5.0;

	// When we reach this height below the train while crashing, we'll expode
	UPROPERTY(Category = "Crash")
	float CrashExplosionBelowTrainHeight = 1000.0;
	// How heavily we'll shake when crashing
	UPROPERTY(Category = "Crash")
	float CrashShakeAmplitude = 200.0;
	// How fast we'll align yaw with train when crashing
	UPROPERTY(Category = "Crash")
	float CrashAlignWithTrainForce = 5.0;
	// How fast we roll when crashing 
	UPROPERTY(Category = "Crash")
	float CrashRollSpeed = 1440.0;
	// Any player within this radius will be launched when enemy explodes
	UPROPERTY(Category = "Crash")
	float EnemyExplodeLaunchRadius = 2000.0;
	// How fast the player is launched when standing on an exploding enemy
	UPROPERTY(Category = "Crash")
	FVector EnemyExplodeLaunchForce = FVector(-500, -500.0, 2000.0);
	// For how long the player is launched after standing on an exploding enemy
	UPROPERTY(Category = "Crash")
	float EnemyExplodeLaunchForceDuration = 1.0;
	// For how long the player floats after being launched from an exploding enemy
	UPROPERTY(Category = "Crash")
	float EnemyExplodeLaunchFloatDuration = 1.0;
	// How long the point of interest back to the train cart lasts after being launched from exploding enemy
	UPROPERTY(Category = "Crash")
	float EnemyExplodeLaunchPointOfInterestDuration = 1.0;
	// How fast the enemy falls after being destroyed
	UPROPERTY(Category = "Crash")
	FVector EnemyDestroyedFallVelocity = FVector(2500.0, 0.0, -750.0);

	// Damage scale of each shoulder turret projectile impact against us
	UPROPERTY(Category = "Health")
	float DamageFromTurretsFactor = 0.02;

	// Damage scale of each shoulder turret projectile impact against our forcefield
	UPROPERTY(Category = "ForceField")
	float ForceFieldDamageFromTurretsFactor = 0.1;

	// Time before forcefield breach starts recovering after being breached. 
	UPROPERTY(Category = "ForceField")
	float ForceFieldBreachPauseDuration = 1.0;

	// Time before forcefield recovers fully after breach pause. 
	UPROPERTY(Category = "ForceField")
	float ForceFieldBreachRecoveryDuration = 5.0;

	UPROPERTY(Category = "Camera")
	float OnCarCameraSettingsBlendtime = 2.0;
}