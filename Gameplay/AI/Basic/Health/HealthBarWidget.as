enum EHealthBarSize
{
	Normal,
	Small,
	Big,
}

UCLASS(Abstract)
class UHealthBarWidget : UHazeUserWidget
{
	UPROPERTY(Category = "HealthBar")
	float Health = 1.0;

	UPROPERTY(Category = "HealthBar")
	float MaxHealth = 1.0;

	UPROPERTY(Category = "HealthBar")
	float RecentHealth = 1.0;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "HealthBar")
	float WobbleDamageThreshold = 0.1;

	float RecentlyDamagedTimer = 0.0;

	// How long it will take for the recent-damage value to start decreasing
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "HealthBar")
	float RecentDamageLerpDelay = 0.5;

	// How fast the recent damage lerps away after the delay
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "HealthBar")
	float RecentDamageLerpSpeed = 8.0;

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void InitHealthBar(float InMaxHealth)
	{
		MaxHealth = InMaxHealth;
		Health = InMaxHealth;
		RecentHealth = InMaxHealth;
		RecentlyDamagedTimer = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{		
		RecentlyDamagedTimer -= DeltaTime;
		if (RecentlyDamagedTimer < 0.0)
			RecentHealth = Math::Lerp(RecentHealth, Health, RecentDamageLerpSpeed * DeltaTime);
	}

	UFUNCTION(BlueprintCallable)
	void SnapHealthTo(float NewHealth)
	{
		Health = Math::Clamp(NewHealth, 0, MaxHealth);
		RecentHealth = Health;
		RecentlyDamagedTimer = 0.0;
	}

	UFUNCTION(BlueprintCallable)
	void SetHealthAsDamage(float NewHealth)
	{
		if (Math::IsNearlyEqual(NewHealth, Health))
			return;

		Health = Math::Clamp(NewHealth, 0, MaxHealth);
		RecentlyDamagedTimer = RecentDamageLerpDelay;

		// So 20% of health-delta in one burst is considered maximum wobbling
		float WolleyDamagePercent = (RecentHealth - Health) / MaxHealth;
		float Wobble = WolleyDamagePercent / WobbleDamageThreshold;
		OnAddBarWobble(Wobble);
	}

	UFUNCTION(BlueprintCallable)
	void TakeDamage(float Damage)
	{
		SetHealthAsDamage(Health - Damage);
	}

	UFUNCTION(BlueprintEvent)
	void OnAddBarWobble(float Magnitude)
	{
	}

	// Gets the current health as a percentege of max health
	UFUNCTION(BlueprintPure, Category = "HealthBar")
	float GetHealthPercentage()
	{
		if (MaxHealth <= 0.0)
			return 0.0;

		return Math::Saturate(Health / MaxHealth);
	}

	// Gets the recent damage as a percentege of max health
	UFUNCTION(BlueprintPure, Category = "HealthBar")
	float GetRecentDamagePercentage()
	{
		if (MaxHealth <= 0.0)
			return 0.0;

		return Math::Saturate(RecentHealth / MaxHealth);
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void SetScreenSpaceOffset(int Offset) {}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void SetBarSize(EHealthBarSize Size) {}
}