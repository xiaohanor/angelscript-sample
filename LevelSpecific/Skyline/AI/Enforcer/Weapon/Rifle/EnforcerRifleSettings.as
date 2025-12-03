class UEnforcerRifleSettings : UHazeComposableSettings
{
	// Seconds in between launched projectiles
	UPROPERTY(Category = "Attack")
	float LaunchInterval = 5.0;

	UPROPERTY(Category = "Attack")
	float BulletStreamCooldown = 2.0;

	// For how long each projectile should remain primed until it's launched
	UPROPERTY(Category = "Attack")
	float PrimeDuration = 0.0;

	// Initial impulse speed of projectiles
	UPROPERTY(Category = "Attack")
	float LaunchSpeed = 3000.0;

	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Attack")
	float TelegraphDuration = 0.75;

	// For how long the weapon anticipates before launching projectiles
	UPROPERTY(Category = "Attack")
	float AnticipationDuration = 0.25;

	// Cost of this attack in gentleman system
	UPROPERTY(Category = "Attack")
	EGentlemanCost GentlemanCost = EGentlemanCost::Medium;

	UPROPERTY(Category = "Attack")
	float ScatterPitch = 0.4;

	UPROPERTY(Category = "Attack")
	float ScatterYaw = 0.5;

	UPROPERTY(Category = "Damage")
	float StreamPredictionTime = 0.7;

	UPROPERTY(Category = "Damage")
	float PlayerDamage = 0.1;

	UPROPERTY(Category = "Damage")
	float AIDamage = 1;

	UPROPERTY(Category = "Damage")
	int StreamHighDamageThreshold = 0;

	UPROPERTY(Category = "Damage")
	float DeathForceScale = 1.0;

	UPROPERTY(Category = "Damage")
	float StreamHighDamageCooldown = 1;

	UPROPERTY(Category = "Damage")
	float StreamHighDamage = 0.5;

	UPROPERTY(Category = "Damage")
	float StreamLowDamage = 0.05;

	UPROPERTY(Category = "Damage")
	int StreamStumbleThreshold = 3;

	UPROPERTY(Category = "Damage")
	float StreamStumbleDuration = 0.4;

	UPROPERTY(Category = "Damage")
	float StreamStumbleDistance = 250.0;

	// How many projectiles fired in a rifle burts
	UPROPERTY(Category = "Attack")
	int ProjectileAmount = 6;

	// How much time between each projectile in a burst
	UPROPERTY(Category = "Attack")
	float TimeBetweenBurstProjectiles = 0.1;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MinimumAttackRange = 300.0;

	UPROPERTY(Category = "Cooldown")
	float AttackTokenCooldown = 1.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Recovery")
	float RecoveryDuration = 1.5;

	// Multiply the speed by this when the projectile is deflected
	UPROPERTY(Category = "Deflect")
	float DeflectSpeedMultiplier = 2.0;
}
