class ASkylineBikeTowerTargetable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponTargetableComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;
	default HealthComp.MaxHealth = 0.0;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;
	default HealthBarComp.SetHealthBarEnabled(false);

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent BikeWeaponProjectileResponseComp;

	UPROPERTY(EditAnywhere)
	FVector HealthBarOffset = FVector::UpVector * 300.0;

	bool bIsDead = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BikeWeaponProjectileResponseComp.OnImpact.AddUFunction(this, n"HandleProjectileImpact");

		UBasicAIHealthBarSettings::SetHealthBarOffset(this, HealthBarOffset, this);
	}

	UFUNCTION()
	private void HandleProjectileImpact(FGravityBikeWeaponImpactData ImpactData)
	{
		if(bIsDead)
			return;

		HealthComp.TakeDamage(ImpactData.Damage, EDamageType::Default, ImpactData.Instigator);

		BP_OnProjectileImpact();

		if (HealthComp.IsDead())
			CrumbDie();
	}

	UFUNCTION()
	void Die()
	{
		if(bIsDead)
			return;

		CrumbDie();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnProjectileImpact() {}

	UFUNCTION(CrumbFunction)
	private void CrumbDie()
	{
		if(bIsDead)
			return;

		bIsDead = true;
		BP_OnDie();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDie() {}
};