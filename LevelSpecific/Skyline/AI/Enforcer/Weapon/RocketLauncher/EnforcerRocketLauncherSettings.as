class UEnforcerRocketLauncherSettings : UHazeComposableSettings
{
	// Seconds in between launched projectiles
	UPROPERTY(Category = "Launch")
	float LaunchInterval = 2.5;

	// For how long the projectile should remain primed until it's launched
	UPROPERTY(Category = "Launch")
	float PrimeDuration = 0.5;

	// Impulse speed of projectile
	UPROPERTY(Category = "Launch")
	float LaunchSpeed = 1500.0;

	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Launch")
	float TelegraphDuration = 1.3;

	UPROPERTY(Category = "Launch")
	float ShootDuration = 1.2;

	UPROPERTY(Category = "Appear")
	float AppearSpeed = 1000.0;

	UPROPERTY(Category = "Appear")
	float AppearTurnDuration = 1;

	UPROPERTY(Category = "Appear")
	float AppearHeight = 250;

	// Cost of this attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost GentlemanCost = EGentlemanCost::Large;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MinimumAttackRange = 1000.0;

	// Disable homing when coming withing this distance
	UPROPERTY(Category = "Attack")
	float HomingStopWithinDistance = 600;

	// Homing should aim at the target with this Z offset
	UPROPERTY(Category = "Attack")
	float HomingTargetOffset = 0.0;

	// How much damage does the rocket projectile deal
	UPROPERTY(Category = "Attack")
	float RocketDamagePlayer = 0.9;

	// How much damage does the rocket projectile deal
	UPROPERTY(Category = "Attack")
	float RocketDamageNpc = 1.5;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Recovery")
	float RecoveryDuration = 2.0;

	UPROPERTY(Category = "Cooldown")
	float AttackTokenCooldown = 3.0;
}
