class ATundra_IcePalace_CourtyardLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	ATundraTreeGuardianRangedShootProjectileSpawner ShootProjectileSpawner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShootProjectileSpawner.OnShootProjectileLaunched.AddUFunction(this, n"OnShootProjectileLaunched");
	}

	UFUNCTION()
	private void OnShootProjectileLaunched(ATundraTreeGuardianRangedShootProjectile Projectile)
	{
		BP_RangedShootProjectileLaunched(Projectile);
	}

	UFUNCTION(BlueprintEvent)
	void BP_RangedShootProjectileLaunched(ATundraTreeGuardianRangedShootProjectile Projectile)
	{}
};