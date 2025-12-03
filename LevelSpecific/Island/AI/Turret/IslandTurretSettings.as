class UIslandTurretSettings : UHazeComposableSettings
{
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
	float LaunchSpeed = 1400.0;

	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Launch")
	float TelegraphDuration = 1.0;

	// How many projectiles fired in a rifle burts
	UPROPERTY(Category = "Attack")
	int ProjectileAmount = 5;

	// How much damage on player
	UPROPERTY(Category = "Attack")
	float ProjectileDamagePlayer = 0.1;

	// How much damage on npc
	UPROPERTY(Category = "Attack")
	float ProjectileDamageNpc = 0.5;

	// How much time between each projectile in a burst
	UPROPERTY(Category = "Attack")
	float TimeBetweenBurstProjectiles = 0.5;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MinimumAttackRange = 300.0;

	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 3.0;

	// Multiply the speed by this when the projectile is deflected
	UPROPERTY(Category = "Deflect")
	float DeflectSpeedMultiplier = 3.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Recovery")
	float RecoveryDuration = 1.0;

	// Stay hacked this long
	UPROPERTY(Category = "Hack")
	float HackedDuration = 10.0;
}
