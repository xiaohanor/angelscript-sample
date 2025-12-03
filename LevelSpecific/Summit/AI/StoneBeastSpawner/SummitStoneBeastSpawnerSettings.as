class USummitStoneBeastSpawnerSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Health")
	float DamageFromSword = 1.0;

	UPROPERTY(Category = "Regeneration")
	float RegenerationRate = 0.5;

	UPROPERTY(Category = "Regeneration")
	float RegenerationPauseBothPlayerHitWindow = 4.0; 

	UPROPERTY(Category = "Regeneration")
	float RegenerationPauseFromBothPlayerHit = 1.0; 

	UPROPERTY(Category = "SpawnProjectile")
	float SpawnProjectileGravity = 4000.0;

	UPROPERTY(Category = "SpawnProjectile")
	float SpawnProjectileLaunchApex = 800.0;

	UPROPERTY(Category = "SpawnProjectile")
	float SpawnProjectileLandDuration = 0.1;

	UPROPERTY(Category = "SpawnProjectile")
	float SpawnProjectileMaxDuration = 5.0;

	UPROPERTY(Category = "SpawnProjectile")
	float SpawnProjectileBlastRadius = 150.0;

	UPROPERTY(Category = "SpawnProjectile")
	float SpawnProjectileDamage = 0.2;

	UPROPERTY(Category = "SpawnProjectile")
	float SpawnProjectileKnockdownDistance = 150.0;

	UPROPERTY(Category = "SpawnProjectile")
	float SpawnProjectileKnockdownDuration = 0.8;

	UPROPERTY(Category = "SpawnProjectile")
	bool SpawnProjectileBlockedByOtherSpawners = false;
}
