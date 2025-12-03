class USummitCrystalChaserSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackMaxRange = 40000.0;

	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackMinRange = 5000.0;

	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackMinAngle = 30.0;

	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackTelegraphDuration = 1.0;

	// All projectiles used in attack is spawned during this interval, then launched after telegraph duration
	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackDeployDuration = 0.5;

	// How many projectiles to spawn
	UPROPERTY(Category = "ChaserAttack")
	int ChaserAttackNumber = 3;

	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackYawWidth = 30.0;

	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackScatterPitch = 5.0;

	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackCooldown = 1.0;

	UPROPERTY(Category = "ChaserAttack")
	EGentlemanCost ChaserAttackGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackTokenCooldown = 1.0;

	UPROPERTY(Category = "ChaserAttack")
	float ChaserAttackProjectileSpeed = 10000.0;
}
