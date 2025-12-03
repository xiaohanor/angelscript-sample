class USummitKnightHelmetComponent : UStaticMeshComponent
{
	UMaterialInstanceDynamic MeltingMaterial;

	float Health = 1.0;
	float IntactAlpha = 1.0;
	float DissolveAlpha = 0.0;
	float LastDamageTime = -BIG_NUMBER;
	bool bCollision = true;
	bool bCanRegrow = true;
	bool bWorn = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		MeltingMaterial = CreateDynamicMaterialInstance(1);
		SetMaterial(1, MeltingMaterial);
	}

	void Wear()
	{
		if (bWorn)
			return;
		bWorn = true;
		RemoveComponentVisualsBlocker(this);
	}

	void Remove()
	{
		if (!bWorn)
			return;
		bWorn = false;
		AddComponentVisualsBlocker(this);
	}

	bool IsHit(FAcidHit Hit) const
	{
		if (Hit.ImpactLocation.IsWithinDist(WorldLocation, 600.0))
			return true;
		return false;
	}

	void TakeDamage(float HealthFraction)
	{
		Health = Math::Clamp(Health - HealthFraction, 0.0, 1.0);
		LastDamageTime = Time::GameTimeSeconds;
	}

	void Regenerate(float HealthFraction)
	{
		if (bCanRegrow)
			Health = Math::Clamp(Health + HealthFraction, 0.0, 1.0);
	}

	void UpdateMelting(float MeltSpeed, float DissolveSpeed, float UnmeltSpeed, float UndissolveSpeed, float DeltaTime)
	{
		if (Math::IsNearlyEqual(Health, IntactAlpha, KINDA_SMALL_NUMBER))
			IntactAlpha = Health;
		else if (Health < IntactAlpha)
			IntactAlpha = Math::FInterpConstantTo(IntactAlpha, Health, DeltaTime, MeltSpeed);
		else if ((DissolveAlpha < 0.1) && bCanRegrow)
			IntactAlpha = Math::FInterpConstantTo(IntactAlpha, Health, DeltaTime, UnmeltSpeed);

		if ((IntactAlpha < SMALL_NUMBER) && (Health < SMALL_NUMBER))
			DissolveAlpha = Math::FInterpConstantTo(DissolveAlpha, 1.0, DeltaTime, DissolveSpeed);		
		else if ((Health > SMALL_NUMBER) && bCanRegrow)
			DissolveAlpha = Math::FInterpConstantTo(DissolveAlpha, 0.0, DeltaTime, DissolveSpeed);		

		MeltingMaterial.SetScalarParameterValue(n"BlendMelt", 1.0 - IntactAlpha);
		MeltingMaterial.SetScalarParameterValue(n"BlendDissolve", DissolveAlpha);
	}	
};
