class USkylineTurretSettings : UHazeComposableSettings
{
	// Duration to amass before switching to closest target.	
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityDuration = 0.7;

	// Within this range, we refocus if a untargeted target lingers to long
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityRange = 1500.0;


	// Cost of attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost GentlemanCost = EGentlemanCost::Large;

	// Seconds in between launched projectiles
	UPROPERTY(Category = "Launch")
	float LaunchInterval = 5.0;

	// For how long each projectile should remain primed until it's launched
	UPROPERTY(Category = "Launch")
	float PrimeDuration = 0.0;

	// Initial impulse speed of projectiles
	UPROPERTY(Category = "Launch")
	float LaunchSpeed = 8000.0;

	UPROPERTY(Category = "Launch")
	float LaunchGravity = 982.0 * 150.0;

	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Launch")
	float TelegraphDuration = 0.75;



	// How many projectiles fired in a rifle burts
	UPROPERTY(Category = "Attack")
	int ProjectileAmount = 8;

	// How much damage on player
	UPROPERTY(Category = "Attack")
	float ProjectileDamagePlayer = 0.5;

	UPROPERTY(Category = "Attack")
	float AttackScatterYaw = 0.5;
	
	UPROPERTY(Category = "Attack")
	float AttackScatterPitch = 0.5;

	// How much time between each projectile in a burst
	UPROPERTY(Category = "Attack")
	float TimeBetweenBurstProjectiles = 0.15;

	// Maximum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MaxAttackRange = 30000.0;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MinAttackRange = 300.0;

	UPROPERTY(Category = "Attack")
	float AttackCooldown = 0.5;

	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 1.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Recovery")
	float RecoveryDuration = 0.25;

	// Damage inflicted by gravity blade
	UPROPERTY(Category = "Damage")
	float GravityBladeDamage = 0.4;

	UPROPERTY(Category = "Damage")
	float HurtReactionDuration = 0.5;
	
	UPROPERTY(Category = "ForceField")
	float ReplenishAmountPerSecond = 0.1;

	// Slingable damage
	UPROPERTY(Category = "Damage")
	float SlingableDamage = 0.4;
}
