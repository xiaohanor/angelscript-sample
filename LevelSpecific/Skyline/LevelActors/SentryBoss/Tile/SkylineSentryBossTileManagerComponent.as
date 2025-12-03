class USkylineSentryBossTileManagerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Tiles")
	int TilesToHazard = 14;

	UPROPERTY(EditAnywhere, Category = "Tiles")
	int TilesToSpawnMissileTurrets = 4;

	UPROPERTY(EditAnywhere, Category = "Tiles")
	int TilesToSpawnLaserDrones = 5;

	UPROPERTY(EditAnywhere, Category = "Tiles")
	int TilesToSpawnPulse = 5;

	UPROPERTY(EditAnywhere, Category = "Cooldowns")
	float PrepareHazardCooldown = 2;

	UPROPERTY(EditAnywhere, Category = "Cooldowns")
	float SpawnLaserDronesCooldown = 6;

	UPROPERTY(EditAnywhere, Category = "Cooldowns")
	float SpawnPulseTurretsCooldown = 6;

	UPROPERTY(EditAnywhere, Category = "Cooldowns")
	int MaxActiveDrones = 10;

	UPROPERTY(EditAnywhere, Category = "Cooldowns")
	int MaxActivePulseTurrets = 5;

	UPROPERTY(EditAnywhere, Category = "Cooldowns")
	float HazardTelegraphTime = 1.5;

};