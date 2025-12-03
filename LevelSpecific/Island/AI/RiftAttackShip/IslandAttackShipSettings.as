class UIslandAttackShipSettings : UHazeComposableSettings
{

	UPROPERTY(Category = "Movement")
	float TurnDuration = 1.0;

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
	float LaunchSpeed = 4500.0;

	// For how long the laser tracking telegraph before launching projectiles
	UPROPERTY(Category = "Launch")
	float TelegraphDuration = 2.5;

	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Launch")
	float TelegraphLaunchDuration = 1.0;

	// How many projectiles fired in a rifle burts
	UPROPERTY(Category = "Attack")
	int ProjectileAmount = 2;

	// How much damage on player
	UPROPERTY(Category = "Attack")
	float ProjectileDamagePlayer = 0.9;
	
	UPROPERTY(Category = "Attack")
	bool bEnableProjectileKnockdown = true;
	
	UPROPERTY(Category = "Attack")
	FVector ProjectileKnockdownMove = FVector(500, 500, 0);

	UPROPERTY(Category = "Attack")
	float ProjectileKnockdownDuration = 3.0;

	// How much time between each projectile in a burst
	UPROPERTY(Category = "Attack")
	float TimeBetweenBurstProjectiles = 1.3;

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

	// Default damage to Shieldotron from player bullet
	UPROPERTY(Category = "Damage")
	float DefaultDamage = 0.005 * 1.2;

	// Crash minimum speed or base speed.
	UPROPERTY(Category = "Crash")
	float CrashBaseSpeed = 10;

	// Crash max speed added to base speed. Speed is multiplied with speed factor from a normalized curve.
	UPROPERTY(Category = "Crash")
	float CrashMaxSpeedIncrement = 2000;

	// Crash POI duration. If set to -1 it will be cleared after crash capability is deactivated.
	UPROPERTY(Category = "Crash")
	float CrashPOIDuration = -1.0;

	// Crash POI regain input time. How long it will take for us to regain the input after a POI is cleared. Use -1 to apply the blend in time of the POI.		
	UPROPERTY(Category = "Crash")
	float CrashPOIRegainInputTime = 0.0;
	
	// Crash Focus Target Offset is added to the target ship world location.
	UPROPERTY(Category = "Crash")
	FVector CrashPOIFocusTargetOffset = FVector(0,0,175);
}
