class USummitStoneBeastCrystalTurretSettings : UHazeComposableSettings
{
	// Duration to amass before switching to closest target.	
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityDuration = 2.0;

	// Within this range, we refocus if a untargeted target lingers to long
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityRange = 5000.0;

	// Can find
	UPROPERTY(Category = "Perception")
	float AwarenessRange = 30000.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost GentlemanCost = EGentlemanCost::Small;

	// Seconds in between launched projectiles
	UPROPERTY(Category = "Launch")
	float LaunchInterval = 5.0;

	// For how long each projectile should remain primed until it's launched
	UPROPERTY(Category = "Launch")
	float PrimeDuration = 0.0;

	// Initial impulse speed of projectiles
	UPROPERTY(Category = "Launch")
	float LaunchSpeed = 500.0;

	// For how long the laser tracking telegraph before launching projectiles
	UPROPERTY(Category = "Launch")
	float TelegraphDuration = 2.5;

	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Launch")
	float TelegraphLaunchDuration = 1.0;

	// How many projectiles fired in a rifle burts
	UPROPERTY(Category = "Attack")
	int ProjectileAmount = 3;

	// How much damage on player
	UPROPERTY(Category = "Attack")
	float ProjectileDamagePlayer = 0.34;

	UPROPERTY(Category = "Attack")
	FVector ProjectileKnockdownMove = FVector(500, 500, 0);

	UPROPERTY(Category = "Attack")
	float ProjectileKnockdownDuration = 3.0;

	// How much time between each projectile in a burst
	UPROPERTY(Category = "Attack")
	float TimeBetweenBurstProjectiles = 0.5;

	// Maximum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MaxAttackRange = 10000.0;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MinAttackRange = 300.0;

	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 3.5;

	// Range of telegraph laser beam
	UPROPERTY(Category = "Attack")
	float TrackingLaserRange = 10000.0;


	// Wait this long after performing an attack
	UPROPERTY(Category = "Recovery")
	float RecoveryDuration = 1.0;


	// Damage inflicted by player
	UPROPERTY(Category = "Damage")
	float DefaultDamage = 0.34;
}
