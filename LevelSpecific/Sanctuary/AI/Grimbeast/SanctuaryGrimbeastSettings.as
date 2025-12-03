namespace GrimbeastTags
{
	const FName Grimbeast = n"Grimbeast";
	const FName Action = n"Action";
	const FName GrimbeastFacePlayer = n"GrimbeastFacePlayer";

	const FName AnimationBoulder = n"AnimationBoulder";
};

class USanctuaryGrimbeastSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Damage")
	float CentipedeProjectileDamage = 0.15;

	// BOULDER
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderTelegraphDuration = 0.5;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderAnticipationDuration = 0.1;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderAttackDuration = 0.1;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderRecoveryDuration = 3.0;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderSnowballDuration = 3.0;

	UPROPERTY(Category = "Attack|Boulder")
	float BoulderDamage = 0.2;
	
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderProjectileSpeed = 400.0;

	UPROPERTY(Category = "Attack|Boulder")
	float BoulderProjectileGravity = 182.0;

	// MORTAR
	UPROPERTY(Category = "Attack|Mortar")
	float MortarRange = 2300.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarMinRange = 750.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarCooldown = 3.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarTokenCooldown = 3.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarTelegraphDuration = 1.0;
	UPROPERTY(Category = "Attack|Mortar")
	float MortarAnticipationDuration = 0.5;
	UPROPERTY(Category = "Attack|Mortar")
	float MortarAttackDuration = 0.1;
	UPROPERTY(Category = "Attack|Mortar")
	float MortarRecoveryDuration = 2.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarDamage = 0.2;
	
	UPROPERTY(Category = "Attack|Mortar")
	float MortarProjectileSpeed = 500.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarProjectileGravity = 982.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Attack|Mortar")
	EGentlemanCost MortarGentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarPoolLifetime = 15.0;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarPoolDamagePerSecond = 0.25;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarPoolCheckOverlapInterval = 0.1;

	UPROPERTY(Category = "Attack|Mortar")
	float MortarPoolDamageDistance = 500.0;

	// MELEE
	UPROPERTY(Category = "Attack|Melee")
	float MeleeRange = 750.0;

	UPROPERTY(Category = "Attack|Melee")
	float MeleeCooldown = 3.0;

	UPROPERTY(Category = "Attack|Melee")
	float MeleeTokenCooldown = 3.0;

	UPROPERTY(Category = "Attack|Melee")
	float MeleeTelegraphDuration = 1.0;
	UPROPERTY(Category = "Attack|Melee")
	float MeleeAnticipationDuration = 0.5;
	UPROPERTY(Category = "Attack|Melee")
	float MeleeAttackDuration = 0.1;
	UPROPERTY(Category = "Attack|Melee")
	float MeleeRecoveryDuration = 1.0;

	UPROPERTY(Category = "Attack|Melee")
	float MeleeDamage = 0.2;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Attack|Melee")
	EGentlemanCost MeleeGentlemanCost = EGentlemanCost::Small;
};

