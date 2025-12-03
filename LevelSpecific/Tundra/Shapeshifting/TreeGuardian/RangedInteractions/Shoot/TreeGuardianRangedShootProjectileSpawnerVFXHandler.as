struct FTundraTreeGuardianRangedShootProjectileSpawnerOnSpawnEffectParams
{
	UPROPERTY()
	ATundraTreeGuardianRangedShootProjectile SpawnedProjectile;
}

struct FTundraTreeGuardianRangedShootProjectileSpawnerOnLaunchEffectParams
{
	UPROPERTY()
	ATundraTreeGuardianRangedShootProjectile LaunchedProjectile;
}

UCLASS(Abstract)
class UTreeGuardianRangedShootProjectileSpawnerVFXHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawnProjectile(FTundraTreeGuardianRangedShootProjectileSpawnerOnSpawnEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchProjectile(FTundraTreeGuardianRangedShootProjectileSpawnerOnLaunchEffectParams Params) {}
}