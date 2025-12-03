class UFlyingCarHealthRegenerationCapability : UHazeCapability
{
	ASkylineFlyingCar CarOwner;
	USkylineFlyingCarHealthComponent HealthComponent;

	UFlyingCarHealthSettings Settings;

	float RegenStartTimestamp;

	bool bCarDamaged = false;
	bool bRegenDelay = false;

	float CarHealth;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarOwner = Cast<ASkylineFlyingCar>(Owner);
		HealthComponent = USkylineFlyingCarHealthComponent::Get(Owner);

		Settings = UFlyingCarHealthSettings::GetSettings(Owner);

		HealthComponent.OnCarDamaged.AddUFunction(this, n"OnCarDamaged");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CarOwner.IsCarExploding())
			return false;

		if (HealthComponent.CurrentHealth == 0.0)
			return false;

		if (HealthComponent.CurrentHealth == 1.0)
			return false;

		if (!bCarDamaged)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Restart regen if car was damaged again
		if (bCarDamaged)
			return true;

		if (HealthComponent.CurrentHealth == 1.0)
			return true;

		if (HealthComponent.CurrentHealth == 0.0)
			return true;

		if (CarOwner.IsCarExploding())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bCarDamaged = false;
		bRegenDelay = true;
		CarHealth = HealthComponent.GetCurrentHealth();

		HealthComponent.bTempInvincibility = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TickInvincibility();

		TickRegen(DeltaTime);
	}

	void TickInvincibility()
	{
		if (HealthComponent.bTempInvincibility)
		{
			if (ActiveDuration >= Settings.InvincibilityAfterHitDuration)
				HealthComponent.bTempInvincibility = false;
		}
	}

	void TickRegen(float DeltaTime)
	{
		if (bRegenDelay)
		{
			if (ActiveDuration < Settings.RegenStartDelay)
				return;

			// Start regeneration
			bRegenDelay = false;
			RegenStartTimestamp = Time::GameTimeSeconds;
		}

		float ElapsedTime = Time::GameTimeSeconds - RegenStartTimestamp;
		float RegenFraction = Math::Saturate(ElapsedTime / Settings.RegenDuration);

		HealthComponent.UpdateHealth(Math::Saturate(CarHealth + RegenFraction));
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCarDamaged(FSkylineFlyingCarDamage CarDamage)
	{
		bCarDamaged = true;
	}
}