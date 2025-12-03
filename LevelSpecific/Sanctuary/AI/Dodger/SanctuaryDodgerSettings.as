class USanctuaryDodgerSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Height")
	float RangeHeightFactor = 0.3;

	UPROPERTY(Category = "Dodge")
	float DodgeDuration = 0.5;

	UPROPERTY(Category = "Dodge")
	float DodgeSpeed = 500.0;
	
	UPROPERTY(Category = "DarkPortal")
	float DarkPortalPullSpeed = 1000.0;

	UPROPERTY(Category = "DarkPortal")
	float DarkPortalPullAccelerationDuration = 2.0;

	UPROPERTY(Category= "RangedAttack")
	float RangedAttackCooldown = 5.0;

	UPROPERTY(Category= "RangedAttack")
	float RangedAttackTokenCooldown = 3.0;

	UPROPERTY(Category= "RangedAttack")
	float RangedAttackTelegraphDuration = 2.0;

	UPROPERTY(Category= "RangedAttack")
	float RangedAttackAnticipationDuration = 0.4;

	UPROPERTY(Category= "RangedAttack")
	int ProjectileAmount = 12;

	UPROPERTY(Category= "RangedAttack")
	float ProjectileSpeed = 1200.0;

	UPROPERTY(Category= "RangedAttack")
	float ProjectileGravity = 982.0;

	UPROPERTY(Category= "RangedAttack")
	float RangedAttackMaxRange = 2000.0;

	UPROPERTY(Category = "RangedAttack")
	EGentlemanCost RangedAttackGentlemanCost = EGentlemanCost::Medium;

	// How far apart we space projectiles in the ranged attack
	UPROPERTY(Category = "RangedAttack")
	float RangedAttackProjectileSpacing = 100;

	// How much random spacing do we add to projectiles in the ranged attack (should be significatly less than RangedAttackProjectileSpacing to avoid overlapping)
	UPROPERTY(Category = "RangedAttack")
	float RangedAttackProjectileRandomSpacing = 25;

	UPROPERTY(Category= "DamageArea")
	float DamageAreaLifetime = 3.0;

	// Deal damage at this interval
	UPROPERTY(Category= "DamageArea")
	float DamageAreaInterval = 0.5;

	// Deal damage at this interval
	UPROPERTY(Category= "DamageArea")
	float DamageAreaDamage = 0.1;

	UPROPERTY(Category = "Charge")
	EGentlemanCost ChargeGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphDuration = 3.0;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphHeight = 650.0;

	UPROPERTY(Category = "Charge")
	float ChargeHitRadius = 150.0;

	UPROPERTY(Category = "Charge")
	float ChargeDamage = 0.1;

	// UPROPERTY(Category = "Charge")
	// float ChargeKnockdownDistance = 300.0;

	// UPROPERTY(Category = "Charge")
	// float ChargeKnockdownDuration = 1.0;

	// Global cooldown for charge grabs to occur (count from when a grab starts).
	UPROPERTY(Category = "Charge")
	float ChargeGrabGlobalCooldown = 20.0;
	
	// Distance from target player to recover to after a charge
	UPROPERTY(Category = "Charge")
	float ChargeRecoveryDistance = 1000.0;

	// Height relative to target player to recover to after a charge
	UPROPERTY(Category = "Charge")
	float ChargeRecoveryHeight = 600.0;

	// Speed at which to recover after a charge
	UPROPERTY(Category = "Charge")
	float ChargeRecoverySpeed = 1500.0;

	// Max time to attempt charge recovery
	UPROPERTY(Category = "Charge")
	float ChargeRecoveryMaxDuration = 5.0;

	// Wait this long into recovery time before we pick recovery destination
	UPROPERTY(Category = "Charge")
	float ChargeRecoveryDestinationDelay = 0.45;

	UPROPERTY(Category = "Charge")
	float ChargeTokenCooldown = 3.0;

	UPROPERTY(Category = "Grab")
	float GrabDamage = 0.1;

	UPROPERTY(Category = "Grab")
	float GrabDamageCooldown = 3.0;

	// How long do we grab the target
	UPROPERTY(Category = "Grab")
	int GrabDuration = 8.0;

	// How long do we grab the target
	UPROPERTY(Category = "Grab")
	int ReleaseDuration = 1.0;

	// Range at which we start do sleep stir behaviours
	UPROPERTY(Category = "Sleep")
	int SleepStirRange = 750.0;

	// Range at which we wake up from sleep
	UPROPERTY(Category = "Sleep")
	int SleepWakeRange = 350.0;

	// How long it takes to wake up (plays wake up animations)
	UPROPERTY(Category = "Sleep")
	float SleepWakeDuration = 3.33;

	// Speed at which we fly to a landing scenepoint
	UPROPERTY(Category = "Land")
	float ScenepointLandSpeed = 1500.0;

	// Delay before we start landing at a valid landing scenepoint area
	UPROPERTY(Category = "Land")
	float ScenepointLandDelay = 1.0;

	// Delay at which we release a landing scenepoints once the scenepoint area becomes invalid (continues its behaviour if it becomes valid again within this time)
	UPROPERTY(Category = "Land")
	float ScenepointLandReleaseDelay = 1.5;
}
