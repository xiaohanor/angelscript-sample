class AGravitBikeFreeDestructable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent,Attach = Pivot)
	UStaticMeshComponent DestructableMesh;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent ProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AimComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent ImpactComp;

	UPROPERTY(EditAnywhere)
	float ProjectileDamage;

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
		//PrintToScreen("oasasdasdasd", 2.0);
		DestroyActor();
		
	}

	UFUNCTION()
	private void HandleProjectileImpacted(FGravityBikeWeaponImpactData ImpactData)
	{
			HealthComp.TakeDamage(ProjectileDamage, EDamageType::Default, this);

		HealthBarComp.UpdateHealthBarVisibility();

		if (HealthComp.CurrentHealth <= 0.0)
			Die();
	}
		UFUNCTION()
	void Die()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, DestructableMesh.GetWorldLocation(), DestructableMesh.GetWorldRotation());
		DestroyActor();
	}
};