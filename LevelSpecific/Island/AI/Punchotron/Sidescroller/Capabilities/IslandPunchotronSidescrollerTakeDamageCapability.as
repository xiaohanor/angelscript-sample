class UIslandPunchotronSidescrollerTakeDamageCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandRedBlueImpactResponseComponent DamageResponseComp;
	UIslandForceFieldComponent ForceFieldComp;
	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent ::Get(Owner);
		DamageResponseComp = UIslandRedBlueImpactResponseComponent::Get(Owner);
		DamageResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);		
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (ForceFieldComp != nullptr && ForceFieldComp.IsReflectingBullets())
			return;

		HealthComp.TakeDamage(Settings.DefaultDamage * Data.ImpactDamageMultiplier, EDamageType::Projectile, Data.Player);		
		DamageFlash::DamageFlashActor(Owner, 0.1);

		UIslandPunchotronEffectHandler::Trigger_OnDamage(Owner, FIslandPunchotronProjectileImpactParams(Data.ImpactLocation));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronDamage(Game::Mio, FIslandPunchotronPlayerEventData(Owner));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronDamage(Game::Zoe, FIslandPunchotronPlayerEventData(Owner));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
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
	}
};