class USanctuaryRangedGhostSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackRange = 1300.0;

	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackMinRange = 750.0;

	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackMaxAngleDegrees = 45.0;

	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackCooldown = 3.0;

	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackTokenCooldown = 3.0;

	UPROPERTY(Category = "Attack|RangedAttack")
	int RangedAttackProjectileCount = 7;

	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackProjectileIntervalAngle = 10;

	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackTelegraphDuration = 2.0;
	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackAnticipationDuration = 0.5;
	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackAttackDuration = 0.1;
	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackRecoveryDuration = 2.0;

	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackDamage = 0.2;
	
	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackProjectileSpeed = 1500.0;

	UPROPERTY(Category = "Attack|RangedAttack")
	float RangedAttackProjectileGravity = 982.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Attack|RangedAttack")
	EGentlemanCost RangedAttackGentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "Circle")
	float CircleEnterRange = 900.0;

	UPROPERTY(Category = "Circle")
	float CircleMaxRange = 1200.0;

	UPROPERTY(Category = "Circle")
	float CircleDistance = 1000.0;

	UPROPERTY(Category = "Circle")
	float CircleHeight = 100.0;

	UPROPERTY(Category = "Circle")
	float CircleWobble = 100.0;

	UPROPERTY(Category = "Circle")
	float CircleSpeed = 600.0;

	UPROPERTY(Category = "Recover")
	float RecoverDuration = 1.33;
};

