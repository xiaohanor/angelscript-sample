class UIslandWalkerHeadHatchHealthBarComponent : UStaticMeshComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UMaterialInstanceDynamic HealthBarMaterialInstance;
	float CurrentHealth = 1.0;
	float Lagginghealth = 1.0;
	float ReduceLaggingHealthTime = BIG_NUMBER;
	float WobbleAmount = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthBarMaterialInstance = Material::CreateDynamicMaterialInstance(this, GetMaterial(0));
		SetMaterial(0, HealthBarMaterialInstance);
	}

	void Show(FInstigator Instigator)
	{
		RemoveComponentVisualsBlocker(Instigator);
	}

	void Hide(FInstigator Instigator)
	{
		AddComponentVisualsBlocker(Instigator);
	}

	void ModifyHealth(float RemainingHealth)
	{
		if (RemainingHealth < CurrentHealth)
			WobbleAmount = 0.5;

		CurrentHealth = RemainingHealth;
		if (CurrentHealth > Lagginghealth)
		{
			Lagginghealth = CurrentHealth;
			ReduceLaggingHealthTime = BIG_NUMBER;
		}
		else if (ReduceLaggingHealthTime == BIG_NUMBER)
		{
			ReduceLaggingHealthTime = Time::GameTimeSeconds + 0.5;	
		}
	}

	void Update(float DeltaTime)
	{
		HealthBarMaterialInstance.SetScalarParameterValue(n"CurrentHealth", CurrentHealth);

		if ((Lagginghealth > CurrentHealth) && (Time::GameTimeSeconds > ReduceLaggingHealthTime))
		{
			Lagginghealth -= 0.1 * DeltaTime;
			if (Lagginghealth < CurrentHealth)
			{
				Lagginghealth = CurrentHealth;
				ReduceLaggingHealthTime = BIG_NUMBER;
			}
		}
		HealthBarMaterialInstance.SetScalarParameterValue(n"RecentHealth", Lagginghealth);

		WobbleAmount = Math::Max(0.0, WobbleAmount - 0.5 * DeltaTime);
		HealthBarMaterialInstance.SetScalarParameterValue(n"DamageWobble", WobbleAmount);
	}
}
