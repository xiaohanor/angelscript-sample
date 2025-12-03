class AGravityBikeFreeObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DestructableMesh;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent ProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AimComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent ImpactComp;

	UPROPERTY(EditDefaultsOnly, Category =" Settings")
	UNiagaraSystem HitEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileResponseComp.OnImpact.AddUFunction(this, n"HandleProjectileImpacted");
		ImpactComp.OnImpact.AddUFunction(this, n"HandleBikeImpact");
	}

	UFUNCTION()
	private void HandleBikeImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
		GravityBike.GetDriver().DamagePlayerHealth(0.1);
		HandleDestroyed();
		
	}
	
	UFUNCTION()
	private void HandleProjectileImpacted(FGravityBikeWeaponImpactData ImpactData)
	{
		HandleDestroyed();
	}

	void HandleDestroyed()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, DestructableMesh.GetWorldLocation(), DestructableMesh.GetWorldRotation());
		DestroyActor();
	}
};