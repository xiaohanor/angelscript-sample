class UEnforcerShotgunSettings : UHazeComposableSettings
{
	// Seconds in between each salvo
	UPROPERTY(Category = "Launch")
	float SalvoInterval = 2.0;

	// For how long the projectile should remain primed until it's launched
	UPROPERTY(Category = "Launch")
	float PrimeDuration = 0.1;

	// Initial impulse speed of projectiles
	UPROPERTY(Category = "Launch")
	float LaunchSpeed = 1500.0;

	// Cost of this attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost GentlemanCost = EGentlemanCost::Medium;

	// How many shots we fire in between each recovery
	UPROPERTY(Category = "Attack")
	int NumShots = 1;

	// Time from when shooting animation starts until shot is launched
	UPROPERTY(Category = "Attack")
	float LaunchDelay = 0.75;

	// Time after shooting animation start until next shooting animation starts
	UPROPERTY(Category = "Attack")
	float ShootInterval = 2.0;

	// How many bullets fired in a shotgun attack
	UPROPERTY(Category = "Attack")
	int BulletAmount = 1;

	// Horizontal scatter in degrees
	UPROPERTY(Category = "Attack")
	float ScatterYaw = 0.0;

	// Space bullets across yaw range
	UPROPERTY(Category = "Attack")
	bool ScatterYawSpacing = true;

	// Vertical scatter in degrees
	UPROPERTY(Category = "Attack")
	float ScatterPitchMin = -0.0; 

	// Vertical scatter in degrees
	UPROPERTY(Category = "Attack")
	float ScatterPitchMax = 0.0;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MinimumAttackRange = 350.0;

	// How far ahead should we try to predict the player position when choosing aim position (based on bullets speed and player velocity)
	UPROPERTY(Category = "Attack")
	float PredictionFactor = 0.5;

	UPROPERTY(Category = "Cooldown")
	float AttackTokenCooldown = 3.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Recovery")
	float RecoveryDuration = 1.5;

	// Player damage
	UPROPERTY(Category = "Projectile")
	float PlayerDamage = 0.2;

	// Damage multiplier
	UPROPERTY(Category = "Projectile")
	float AdditionalCloseDamage = 1.0;

	// Damage multiplier within this distance 
	UPROPERTY(Category = "Projectile")
	float AdditionalCloseDamageRange = 2000;

	// Player taking damge will also stumble within this distance 
	UPROPERTY(Category = "Projectile")
	float StumbleRange = 2000;

	UPROPERTY(Category = "Projectile")
	float IgnoreCollisionRange = 200.0;

	UPROPERTY(Category = "Projectile")
	float ProjectileWidth = 100.0;
}