class ASkylineBossArenaDestructible : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent ProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent ImpactResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileResponseComp.OnImpact.AddUFunction(this, n"HandleProjectileImpact");
		ImpactResponseComp.OnImpact.AddUFunction(this, n"HandleImpact");
	}

	UFUNCTION()
	private void HandleProjectileImpact(FGravityBikeWeaponImpactData ImpactData)
	{
		Break();
	}

	UFUNCTION()
	private void HandleImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
		Break();
	}

	void Break()
	{
		BP_OnBreak();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnBreak() { }
};