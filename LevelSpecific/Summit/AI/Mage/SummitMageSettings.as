class USummitMageSettings : UHazeComposableSettings
{
	// How long to telegraph teleportation
	UPROPERTY()
	float TeleportTelegraphDuration = 3.0;

	// How long to teleport before reappearing
	UPROPERTY()
	float TeleportDuration = 1.0;

	// How long to wait after appearing from teleport
	UPROPERTY()
	float TeleportCompletedDuration = 1.0;

	// How long to telegraph critter summoning
	UPROPERTY()
	float SummonCritterTelegraphDuration = 0.5;

	// How long to do the summoning move, critter is spawned at the end of this
	UPROPERTY()
	float SummonCritterDuration = 0.5;

	// How long to do recovery from critter summoning
	UPROPERTY()
	float SummonCritterRecoveryDuration = 0.5;

	// Maximum amount of critters to be alive at the same time
	UPROPERTY()
	int MaxCritters = 9;

	// Maximum amount of critters to spawn in each wave
	UPROPERTY()
	int CritterWaveSize = 3;

	UPROPERTY(Category = "CritterSlug")
	float SpawnProjectileGravity = 5982.0;
	
	UPROPERTY(Category = "CritterSlug")
	float SpawnProjectileSpeed = 750.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "CritterSlug")
	EGentlemanCost CritterSlugGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "CritterSlug")
	float CritterSlugTokenCooldown = 5;

	UPROPERTY(Category = "CritterSlug")
	float CritterSlugCooldown = 8;

	UPROPERTY(Category = "SpiritBall")
	int SpiritBallMax = 3;

	UPROPERTY(Category = "SpiritBall")
	float AttackProjectileGravity = 5982.0;

	UPROPERTY(Category = "SpiritBall")
	float AttackProjectileSpeed = 750.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "SpiritBall")
	EGentlemanCost SpiritBallGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "SpiritBall")
	float SpiritBallTokenCooldown = 6;

	UPROPERTY(Category = "SpiritBall")
	float SpiritBallCooldown = 18;

	UPROPERTY(Category = "SpiritBall")
	float SpiritBallDonutIntervalDuration = 6;

	// How long it takes to cast the donut spell
	UPROPERTY(Category = "Donut")
	float DonutDuration = 1;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Donut")
	EGentlemanCost DonutGentlemanBudget = EGentlemanCost::Medium;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Donut")
	EGentlemanCost DonutGentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "Donut")
	float DonutTokenCooldown = 3;

	UPROPERTY(Category = "Donut")
	float DonutCooldown = 6;

	UPROPERTY(Category = "Donut")
	float DonutMaximumRadius = 9000;

	UPROPERTY(Category = "Donut")
	float DonutExpansionSpeed = 1300;

	UPROPERTY(Category = "Donut")
	float DonutDamageWidth = 80;
};