class USummitCrystalSkullSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Targeting")
	float TargetingRange = 50000.0;

	UPROPERTY(Category = "Targeting")
	float TargetingInterval = 0.5;

	UPROPERTY(Category = "Movement")
	float TurnDuration = 3.5;

	UPROPERTY(Category = "Tracking")
	float TrackTargetRange = 100000.0;

	UPROPERTY(Category = "Tracking")
	float TrackTargetPitchClamp = 15.0;


	UPROPERTY(Category = "Holding")
	float HoldingSpeed = 2000.0;

	UPROPERTY(Category = "Holding")
	float HoldingRadius = 10000.0;

	UPROPERTY(Category = "Evade")
	float EvadeMoveSpeed = 7000.0;

	UPROPERTY(Category = "Evade")
	float EvadeNearMoveSpeed = 0.0;

	UPROPERTY(Category = "Evade")
	float EvadeRange = 60000.0;

	UPROPERTY(Category = "Evade")
	float EvadeNearRange = 6000.0;


	UPROPERTY(Category = "SpawnCritters")
	float SpawnCrittersMaxRange = 80000.0;

	UPROPERTY(Category = "SpawnCritters")
	float SpawnCrittersMinRange = 20000.0;

	UPROPERTY(Category = "SpawnCritters")
	float SpawnCrittersMinAngle = 40.0;

	UPROPERTY(Category = "SpawnCritters")
	float SpawnCrittersDuration = 5.0;

	UPROPERTY(Category = "SpawnCritters")
	float SpawnCrittersCooldown = 5.0;


	UPROPERTY(Category = "ArcAttack")
	float ArcAttackMaxRange = 40000.0;

	UPROPERTY(Category = "ArcAttack")
	float ArcAttackMinRange = 10000.0;

	UPROPERTY(Category = "ArcAttack")
	float ArcAttackMinAngle = 30.0;

	UPROPERTY(Category = "ArcAttack")
	float ArcAttackTelegraphDuration = 2.0;

	// All projectiles used in attack is spawned during this interval, then launched after telegraph duration
	UPROPERTY(Category = "ArcAttack")
	float ArcAttackDeployDuration = 1.0;

	// How many projectiles to spawn
	UPROPERTY(Category = "ArcAttack")
	int ArcAttackNumber = 15;

	UPROPERTY(Category = "ArcAttack")
	float ArcAttackYawWidth = 90.0;

	UPROPERTY(Category = "ArcAttack")
	float ArcAttackScatterPitch = 5.0;

	UPROPERTY(Category = "ArcAttack")
	float ArcAttackCooldown = 1.0;

	UPROPERTY(Category = "ArcAttack")
	EGentlemanCost ArcAttackGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "ArcAttack")
	float ArcAttackTokenCooldown = 1.0;

	UPROPERTY(Category = "ArcAttack")
	float ArcAttackProjectileSpeed = 5000.0;


	UPROPERTY(Category = "ArcProjectile")
	float ArcProjectileTriggerRadius = 1500;

	UPROPERTY(Category = "ArcProjectile")
	float ArcProjectileTriggerHeight = 500;

	UPROPERTY(Category = "ArcProjectile")
	float ArcProjectileDamage = 0.25;

	// Player taking damage will be immune to further damage for this long
	UPROPERTY(Category = "ArcProjectile")
	float ArcProjectileDamageCooldown = 1.0;

	UPROPERTY(Category = "ArcProjectile")
	float ArcProjectileDamageRadius = 2000;

	UPROPERTY(Category = "ArcProjectile")
	float ArcProjectileLifetime = 10.0;


	UPROPERTY(Category = "Recover")
	float RecoverDuration = 4.5;

	UPROPERTY(Category = "ArcAttack")
	float RecoverMoveSpeed = 2000.0;


	// How many shields to deploy
	UPROPERTY(Category = "DeployShields")
	int DeployShieldsNumber = 24;

	UPROPERTY(Category = "DeployShields")
	float DeployShieldsSmashCooldown = 10.0;

	UPROPERTY(Category = "DeployShields")
	float DeployShieldsDuration = 2.0;

	UPROPERTY(Category = "DeployShields")
	float DeployShieldsDistance = 4000.0;

	UPROPERTY(Category = "DeployShields")
	float DeployShieldsOrbitalSpeed = 2000.0;

	UPROPERTY(Category = "DeployShields")
	float DeployShieldsRollSpeed = 0.2;


	UPROPERTY(Category = "Chase")
	float ChaseSpeed = 20000.0;

	UPROPERTY(Category = "Chase")
	float ChaseRange = 120000.0;

	UPROPERTY(Category = "Chase")
	float ChaseMaxAngle = 10.0;

	UPROPERTY(Category = "Chase")
	FVector ChaseFlankingOffset = FVector(20000.0, 2000.0, 1000.0);

	UPROPERTY(Category = "Chase")
	float ChaseMinDuration = 5.0;


	UPROPERTY(Category = "LayMines")
	float LayMinesMaxRange = 30000.0;

	UPROPERTY(Category = "LayMines")
	float LayMinesMinRange = 20000.0;

	UPROPERTY(Category = "LayMines")
	float LayMinesMinAngle = 30.0;

	UPROPERTY(Category = "LayMines")
	float LayMinesTelegraphDuration = 1.0;

	UPROPERTY(Category = "LayMines")
	float LayMinesDuration = 3.0;

	UPROPERTY(Category = "LayMines")
	float LayMinesRecoverDuration = 4.5;

	UPROPERTY(Category = "LayMines")
	int LayMinesNumber = 8;

	UPROPERTY(Category = "LayMines")
	float LayMinesScatterYaw = 45.0;

	UPROPERTY(Category = "LayMines")
	float LayMinesScatterPitch = 0.0;

	UPROPERTY(Category = "LayMines")
	float LayMinesCooldown = 2.0;

	UPROPERTY(Category = "LayMines")
	float LayMinesMoveSpeed = 2500.0;

	UPROPERTY(Category = "LayMines")
	EGentlemanCost LayMinesGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "LayMines")
	float LayMinesTokenCooldown = 1.0;

	UPROPERTY(Category = "Mine")
	float MinesMoveSpeed = 8000.0;

	UPROPERTY(Category = "Mine")
	float MineTriggerRadius = 1500;

	UPROPERTY(Category = "Mine")
	float MineDamage = 0.25;

	UPROPERTY(Category = "Mine")
	float MineDamageRadius = 2000;

	UPROPERTY(Category = "Mine")
	float MineDamageInnerRadius = 1000000;

	UPROPERTY(Category = "Mine")
	float MineSelfDestructDuration = 4.0;
}
