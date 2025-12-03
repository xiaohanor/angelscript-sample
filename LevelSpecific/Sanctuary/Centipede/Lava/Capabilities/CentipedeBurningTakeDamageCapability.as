class UCentipedeBurningTakeDamageCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ACentipede Centipede;
	UCentipedeLavaIntoleranceComponent LavaIntoleranceComponent;
	UPlayerCentipedeComponent ZoePlayerCentipedeComponent;
	UPlayerCentipedeComponent MioPlayerCentipedeComponent;
	TArray<TSubclassOf<AHazeActor>> BurningFakeyInstigatorClasses;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LavaIntoleranceComponent = UCentipedeLavaIntoleranceComponent::Get(Owner);
		Centipede = Cast<ACentipede>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (LavaIntoleranceComponent.Burns.Num() == 0)
			return false;

		if (LavaIntoleranceComponent.bIsRespawning)
			return false;

		if (DevTogglesPlayerHealth::ZoeGodmode.IsEnabled())
			return false;
		if (DevTogglesPlayerHealth::MioGodmode.IsEnabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (LavaIntoleranceComponent.bIsRespawning)
			return true;

		if (LavaIntoleranceComponent.Burns.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LavaIntoleranceComponent.Burns.Reset(32);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (LavaIntoleranceComponent.bIsRespawning)
			return;

#if EDITOR
		int i = 0;
		for (auto Burn : LavaIntoleranceComponent.Burns)
		{
			FString Category = "Burn " + i;
			i++;
			TEMPORAL_LOG(Centipede, "Lava Intolerance").Value(Category + " dps", Burn.DamagePerSecond);
			TEMPORAL_LOG(Centipede, "Lava Intolerance").Value(Category + " dur", Burn.DamageDuration);
			TEMPORAL_LOG(Centipede, "Lava Intolerance").Value(Category + " timer", Burn.DamageTimer);
			TEMPORAL_LOG(Centipede, "Lava Intolerance").Value(Category + " ff", Burn.bTriggerForceFeedback);
			TEMPORAL_LOG(Centipede, "Lava Intolerance").Value(Category + " source", Burn.SourceDamager);
		}
#endif
		
		ApplyDamageOverTime(DeltaTime);
		RemoveRedundantDamageSources();
	}

	private void ApplyDamageOverTime(float DeltaSeconds)
	{
		float NewHealth = LavaIntoleranceComponent.Health.Value;
		BurningFakeyInstigatorClasses.Empty();
		for (FCentipedeLavaDamageOverTime& Source : LavaIntoleranceComponent.Burns)
		{
			float Multiplier = DeltaSeconds;
			if (Source.DamageTimer + DeltaSeconds >= Source.DamageDuration)
				Multiplier = Source.DamageDuration - Source.DamageTimer;
			
			bool bDidDamage = false;
			if (Source.SourceDamager != nullptr && !BurningFakeyInstigatorClasses.Contains(Source.SourceDamager))
			{
				bDidDamage = true;
				float SourceDamage = Source.DamagePerSecond * Multiplier;
				NewHealth -= SourceDamage;
				BurningFakeyInstigatorClasses.Add(Source.SourceDamager);
			}

			if (SanctuaryCentipedeDevToggles::Draw::Burning.IsEnabled())
				PrintToScreen(bDidDamage ? "damaged" : "no dmg", 0.0, bDidDamage ? ColorDebug::Red : ColorDebug::Green);

			Source.DamageTimer += DeltaSeconds;
		}

		if (HasControl())
			LavaIntoleranceComponent.SetHealth(Math::Clamp(NewHealth, 0.0, 1.0));
	}

	private void RemoveRedundantDamageSources()
	{
		for (int i = 0; i < LavaIntoleranceComponent.Burns.Num(); ++i)
		{
			if (LavaIntoleranceComponent.Burns[i].DamageTimer > LavaIntoleranceComponent.Burns[i].DamageDuration)
				LavaIntoleranceComponent.Burns.RemoveAtSwap(i);
		}
	}
}