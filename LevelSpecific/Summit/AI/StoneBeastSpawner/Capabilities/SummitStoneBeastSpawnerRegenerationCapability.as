class USummitStoneBeastSpawnerRegenerationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"StoneBreakableRegen");

	default TickGroup = EHazeTickGroup::Gameplay;
	
	UBasicAIHealthComponent HealthComp;
	UBasicAIHealthBarComponent HealthBarComp;
	USummitStoneBeastSpawnerSettings Settings;

	TPerPlayer<float> LastHits;
	float BothPlayerHitCooldown = 0.0;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
		Settings = USummitStoneBeastSpawnerSettings::GetSettings(Owner);
		UDragonSwordCombatResponseComponent SwordResponseComp = UDragonSwordCombatResponseComponent::Get(Owner);
		SwordResponseComp.OnHit.AddUFunction(this,n"OnSwordHit");
	}

	UFUNCTION()
	private void OnSwordHit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Instigator);
		if (Player == nullptr)
			return;
		LastHits[Player] = Time::GameTimeSeconds;
		if (Time::GetGameTimeSince(LastHits[Player.OtherPlayer]) < Settings.RegenerationPauseBothPlayerHitWindow)
			BothPlayerHitCooldown = Time::GameTimeSeconds + Settings.RegenerationPauseFromBothPlayerHit;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Time::GameTimeSeconds < BothPlayerHitCooldown)
			return false;
		if (HealthComp.GetHealthFraction() < 1.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds < BothPlayerHitCooldown)
			return true;
		if (HealthComp.GetHealthFraction() < 1.0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float NewHealth = Math::Min(HealthComp.MaxHealth, HealthComp.CurrentHealth + Settings.RegenerationRate * DeltaTime);
		HealthComp.SetCurrentHealth(NewHealth);
		HealthBarComp.SnapBarToHealth();
	}
};