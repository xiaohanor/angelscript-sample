class UEnforcerDualWieldingSettings : UHazeComposableSettings
{
	//
	// Rifle settings
	//

	// Seconds in between launched projectiles
	UPROPERTY(Category = "Rifle")
	float RifleLaunchInterval = 5.0;

	// For how long each projectile should remain primed until it's launched
	UPROPERTY(Category = "Rifle")
	float RiflePrimeDuration = 0.0;

	// Initial impulse speed of projectiles
	UPROPERTY(Category = "Rifle")
	float RifleLaunchSpeed = 2000.0;

	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Rifle")
	float RifleTelegraphDuration = 1.0;

	// Cost of this attack in gentleman system
	UPROPERTY(Category = "Rifle")
	EGentlemanCost RifleGentlemanCost = EGentlemanCost::XSmall;

	//UPROPERTY(Category = "Damage")
	//float RiflePlayerDamage = 0.1;

	//UPROPERTY(Category = "Damage")
	//float AIDamage = 1;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Rifle")
	float RifleMinimumAttackRange = 300.0;

	UPROPERTY(Category = "Rifle")
	float RifleAttackTokenCooldown = 3.0;
	
	// Wait this long after performing an attack
	//UPROPERTY(Category = "Recovery")
	//float RifleRecoveryDuration = 2.0;

	// Multiply the speed by this when the projectile is deflected
	//UPROPERTY(Category = "Deflect")
	//float DeflectSpeedMultiplier = 2.0;


	//
	// Sticky Bomb Settings
	//

	UPROPERTY(Category = "StickyBomb")
	float StickyBombDuration = 2.5;

	// Scale we want to reach before exploding
	UPROPERTY(Category = "StickyBomb")
	float StickyBombTargetScale = 1;

	// Initial impulse speed of projectiles
	UPROPERTY(Category = "StickyBomb")
	float StickyBombLaunchSpeed = 3200.0;

	UPROPERTY(Category = "StickyBomb")
	float StickyBombGravity = 982.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "StickyBomb")
	float StickyBombInitialCooldown = 6.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "StickyBomb")
	float StickyBombInterval = 4.0;

	// Telegraph duration before launching projectiles
	UPROPERTY(Category = "StickyBomb")
	float StickyBombTelegraphDuration = 0.4;

	// For how long the enforcer does its launching projectile state
	UPROPERTY(Category = "StickyBomb")
	float StickyBombAttackDuration = 0.6;

	// Cost of this attack in gentleman system
	UPROPERTY(Category = "StickyBomb")
	EGentlemanCost StickyBombGentlemanCost = EGentlemanCost::XSmall;

	// Maximum distance for using weapon
	UPROPERTY(Category = "StickyBomb")
	float StickyBombAttackRange = 6500.0;

	// Minimum distance for using weapon
	UPROPERTY(Category = "StickyBomb")
	float StickyBombMinimumAttackRange = 300.0;

	// How much damage does the StickyBomb deal
	UPROPERTY(Category = "StickyBomb")
	float StickyBombDamagePlayer = 0.8;

	// Wait this long after performing an attack
	UPROPERTY(Category = "StickyBomb")
	float StickyBombRecoveryDuration = 1.0;

	// StickyBomb token cooldown duration
	UPROPERTY(Category = "StickyBomb")
	float StickyBombAttackTokenCooldown = 3.0;
}
