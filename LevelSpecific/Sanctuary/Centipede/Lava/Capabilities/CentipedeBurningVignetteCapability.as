class UCentipedeBurningVignetteCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ACentipede Centipede;
	UCentipedeLavaIntoleranceComponent LavaIntoleranceComponent;
	UPlayerCentipedeComponent MioPlayerCentipedeComponent;
	UPlayerCentipedeComponent ZoePlayerCentipedeComponent;

	TMap<UCentipedeSegmentComponent, float> SegmentToBurnCooldowns;
	TArray<UCentipedeSegmentComponent> SpawnedParticlesOnSegment;
	bool bLastWasBurning = false;
	UPlayerDamageScreenEffectComponent DamageVignetteComp;
	FHazeAcceleratedFloat AccHealth;

	const float BurnTickTime = 0.8;
	float BurnTickTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LavaIntoleranceComponent = UCentipedeLavaIntoleranceComponent::Get(Owner);
		Centipede = Cast<ACentipede>(Owner);
		DamageVignetteComp = UPlayerDamageScreenEffectComponent::Get(Game::Mio);
		LavaIntoleranceComponent.OnCentipedeBurnAdded.AddUFunction(this, n"FlashBurn");
	}

	UFUNCTION()
	private void FlashBurn()
	{
		if (IsActive())
		{
			DamageVignetteComp.OverrideLastDamageGameTime.Apply(Time::GameTimeSeconds, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DevTogglesPlayerHealth::ZoeGodmode.IsEnabled())
			return false;
		if (DevTogglesPlayerHealth::MioGodmode.IsEnabled())
			return false;
		if (LavaIntoleranceComponent.Burns.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DevTogglesPlayerHealth::ZoeGodmode.IsEnabled())
			return true;
		if (DevTogglesPlayerHealth::MioGodmode.IsEnabled())
			return true;

		bool bNoBurns = LavaIntoleranceComponent.Burns.Num() == 0;
		bool bNoVignette = LavaIntoleranceComponent.VignetteAlpha.Value <= KINDA_SMALL_NUMBER;
		float Health = AccHealth.Value;
		bool bFullHealth = Math::IsNearlyEqual(Health, 1.0, 0.01);
		if (bNoBurns && bNoVignette && bFullHealth)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DamageVignetteComp.bAllowInFullScreen.Apply(true, this);
		DamageVignetteComp.OverrideLastDamageGameTime.Apply(Time::GameTimeSeconds, this);
		AccHealth.SnapTo(1.0);
		BurnTickTimer = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DamageVignetteComp.bAllowInFullScreen.Clear(this);
		DamageVignetteComp.OverrideLastDamageGameTime.Clear(this);
		DamageVignetteComp.OverrideDisplayedHealth.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		BurnTickTimer += DeltaTime;
		if (BurnTickTimer > BurnTickTime)
		{
			BurnTickTimer = Math::Wrap(BurnTickTimer, 0.0, BurnTickTime);
		}

		UpdateVignette(DeltaTime);
	}

	private void UpdateVignette(float DeltaSeconds)
	{
		float VignetteAlpha = Math::Saturate(1.0 - LavaIntoleranceComponent.Health.Value);
		LavaIntoleranceComponent.VignetteAlpha.AccelerateTo(VignetteAlpha, 1.0, DeltaSeconds);
		LavaIntoleranceComponent.BurningAlpha = LavaIntoleranceComponent.VignetteAlpha.Value; 

		AccHealth.AccelerateTo(LavaIntoleranceComponent.Health.Value, 2.0, DeltaSeconds);
		DamageVignetteComp.OverrideDisplayedHealth.Apply(AccHealth.Value, this);
	}

	bool TryCacheThings()
	{
		if (ZoePlayerCentipedeComponent == nullptr)
			ZoePlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Game::Zoe);
		if (MioPlayerCentipedeComponent == nullptr)
			MioPlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Game::Mio);
		return MioPlayerCentipedeComponent != nullptr && ZoePlayerCentipedeComponent != nullptr;
	}
};