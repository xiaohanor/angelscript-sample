class UIslandTurretronSettings : UHazeComposableSettings
{
	// Duration to amass before switching to closest target.	
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityDuration = 0.7;

	// Within this range, we refocus if a untargeted target lingers to long
	UPROPERTY(Category = "Perception")
	float RetargetOnProximityRange = 5000.0;

	// Will not switch to closest target before new target is this much closer than current target.
	UPROPERTY(Category = "Perception")
	float SwitchClosestTargetTresholdDist = 1000.0;

	UPROPERTY(Category = "Perception")
	bool bShouldTrackTarget = true;


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

	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Launch")
	float TelegraphDuration = 1.0;


	// How many projectiles fired in a rifle burts
	UPROPERTY(Category = "Attack")
	int ProjectileAmount = 20;
	
	// How many projectiles fired in a rifle burts in arc attack
	UPROPERTY(Category = "Attack")
	int ArcProjectileAmount = 40;

	// Gives random projectile amount by +- DevationRange
	UPROPERTY(Category = "Attack")
	int ProjectileAmountDeviationRange = 4;

	// How much damage on player
	UPROPERTY(Category = "Attack")
	float ProjectileDamagePlayer = 0.25;

	UPROPERTY(Category = "Attack")
	float AttackScatterYaw = 0.5;
	
	UPROPERTY(Category = "Attack")
	float AttackScatterPitch = 0.5;

	// How much time between each projectile in a burst
	UPROPERTY(Category = "Attack")
	float TimeBetweenBurstProjectiles = 0.05;

	// Maximum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MaxAttackRange = 6000.0;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MinAttackRange = 100.0;

	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 1.0;

	UPROPERTY(Category = "Attack")
	float AttackTokenPersonalCooldown = 3.0;


	// Wait this long after performing an attack
	UPROPERTY(Category = "Recovery")
	float RecoveryDuration = 1.0;


	// Damage inflicted by player bullets on non-shield
	UPROPERTY(Category = "Damage")
	float DefaultDamage = 0.04;

	// Damage inflicted by player bullets on shield
	UPROPERTY(Category = "Damage")
	float ForceFieldDefaultDamage = 0.1;
	
	// Damage inflicted by player bullets
	UPROPERTY(Category = "Damage")
	float HurtReactionDuration = 0.5;

	
	UPROPERTY(Category = "ForceField")
	float ReplenishAmountPerSecond = 0.1;

	UPROPERTY(Category = "Targetable Component")
	float AutoAimMaximumDistance = 5000.0;


	// Contact damage

	// Cooldown time until next contact damage may be dealt to player.
	UPROPERTY(Category = "ContactDamage")
	float ContactDamagePlayerCooldown = 0.4;

	// Damage dealt to player on contact
	UPROPERTY(Category = "ContactDamage")
	float ContactDamageAmount = 0.9;

	// Knockdown duration
	UPROPERTY(Category = "ContactDamage")
	float ContactDamageKnockdownDuration = 1.25;
	
	// Knockdown distance
	UPROPERTY(Category = "ContactDamage")
	float ContactDamageKnockdownDistance = 300.0;
}
