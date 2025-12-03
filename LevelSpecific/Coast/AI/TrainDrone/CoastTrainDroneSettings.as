class UCoastTrainDroneSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Damage")
	float DamageFromProjectilesFactor = 0.015;

	UPROPERTY(Category = "Damage")
	float DamageReactionDuration = 0.3;


	UPROPERTY(Category = "Movement|Wobble")
	float WobbleAmplitude = 80.0;

	UPROPERTY(Category = "Movement|Wobble")
	float WobbleFrequency = 3.0;


	UPROPERTY(Category = "ScanAttack")
	float ScanAttackCooldownTime = 2.0;

	UPROPERTY(Category = "ScanAttack")
	float ScanAttackTelegraphDuration = 0.5;

	UPROPERTY(Category = "ScanAttack")
	float ScanAttackRadius = 1000.0;

	UPROPERTY(Category = "ScanAttack")
	float ScanAttackDamage = 0.5;

	UPROPERTY(Category = "ScanAttack")
	float ScanAttackLaunchPushDuration = 0.5;

	UPROPERTY(Category = "ScanAttack")
	float ScanAttackLaunchFloatDuration = 1.0;

	UPROPERTY(Category = "ScanAttack")
	float ScanAttackLaunchPointOfInterestDuration = 1.0;

	UPROPERTY(Category = "ScanAttack")
	FVector ScanAttackLaunchForce = FVector(-750.0*1.5, 800.0*1.5, 400.0*1.5);


	UPROPERTY(Category = "HoldAtCart")
	float HoldAtCartHeight = 900.0;

	UPROPERTY(Category = "HoldAtCart")
	float HoldAtCartSpeed = 4800.0;


	UPROPERTY(Category = "ScanCart")
	float ScanCartActivationRange = 20000.0;

	UPROPERTY(Category = "ScanCart")
	float ScanCartHeight = 700.0;

	UPROPERTY(Category = "ScanCart")
	float ScanCartSpeed = 1400.0;

	UPROPERTY(Category = "ScanCart")
	float ScanCartPauseDuration = 0.25;

	UPROPERTY(Category = "ScanCart")
	float ScanCartDetectionWidth = 1000.0;

	UPROPERTY(Category = "ScanCart")
	float ScanCartDetectionDepth = 60.0;

	UPROPERTY(Category = "ScanCart")
	float ScanCartCooldown = 3.0;

	UPROPERTY(Category = "ScanCart")
	float ScanCartExtraInFront = 0.0;

	UPROPERTY(Category = "ScanCart")
	float ScanCartExtraBehind = 0.0;


	UPROPERTY(Category = "Movement|CombatPositioning")
	float CombatPositioningRange = 12000.0;

	UPROPERTY(Category = "Movement|CombatPositioning")
	float CombatPositioningSpeed = 5000.0;

	UPROPERTY(Category = "Movement|CombatPositioning")
	float CombatPositioningHeight = 500.0;

	// The drone will not try to go below this vertical distance from a train cart
	UPROPERTY(Category = "Movement|CombatPositioning")
	float CombatPositioningCartMinHeight = 250.0;

	// The drone will not try to go above this vertical distance from a train cart
	UPROPERTY(Category = "Movement|CombatPositioning")
	float CombatPositioningCartMaxHeight = 2000.0;


	UPROPERTY(Category = "ProjectileAttack")
	EGentlemanCost ProjectileAttackGentlemanCost = EGentlemanCost::Medium;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileAttackDamage = 0.0;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileAttackRange = 2600.0;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileAttackCooldownTime = 2.0;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileAttackTokenCooldown = 4.0;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileAttackTelegraphDuration = 1.0;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileAttackTelegraphHeight = 200.0;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileLaunchSpeed = 1000.0;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileGravity = 982.0;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileStartRotationSpeed = 200.0;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileBoloSpawnDistance = 100;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileBoloMinDistance = 150;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileBoloMaxDistance = 250;

	UPROPERTY(Category = "ProjectileAttack")
	FVector ProjectileImpulseForce = FVector(-750.0, 800.0, 800.0);

	// The Z direction of the projectile impulse. X and Y is determined by projectile velocity. 0.0...1.0
	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileImpulseZDirection = 0.5;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileImpulseDuration = 0.5;

	UPROPERTY(Category = "ProjectileAttack")
	float ProjectileImpulseFloatDuration = 0;
}
