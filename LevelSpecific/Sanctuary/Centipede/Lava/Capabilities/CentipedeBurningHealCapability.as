class UCentipedeBurningHealCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ACentipede Centipede;
	UCentipedeLavaIntoleranceComponent LavaIntoleranceComponent;
	UPlayerCentipedeComponent ZoePlayerCentipedeComponent;
	UPlayerCentipedeComponent MioPlayerCentipedeComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LavaIntoleranceComponent = UCentipedeLavaIntoleranceComponent::Get(Owner);
		Centipede = Cast<ACentipede>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;

		if (LavaIntoleranceComponent.Burns.Num() > 0)
			return false;

		if (LavaIntoleranceComponent.Health.Value > 1.0 - KINDA_SMALL_NUMBER)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (LavaIntoleranceComponent.bIsRespawning)
			return true;

		if (LavaIntoleranceComponent.Burns.Num() > 0)
			return true;

		if (LavaIntoleranceComponent.Health.Value > 1.0 - KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LavaIntoleranceComponent.HealthRegenStartsTimer = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LavaIntoleranceComponent.HealthRegenStartsTimer += DeltaTime;
		if (LavaIntoleranceComponent.HealthRegenStartsTimer < LavaIntoleranceComponent.DurationBeforeHealthRegenStarts)
			return;

		float NewHealth = LavaIntoleranceComponent.Health.Value;
		NewHealth += LavaIntoleranceComponent.HealthRegenPerSecond * DeltaTime;
		LavaIntoleranceComponent.SetHealth(Math::Clamp(NewHealth, 0.0, 1.0));
	}
}