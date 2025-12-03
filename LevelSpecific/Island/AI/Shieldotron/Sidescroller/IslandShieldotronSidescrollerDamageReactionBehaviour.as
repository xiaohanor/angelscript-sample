
class UIslandShieldotronSidescrollerDamageReactionBehaviour : UBasicBehaviour
{
	UIslandRedBlueImpactResponseComponent ResponseComp;	
	UBasicAIHealthComponent HealthComp;
	UIslandForceFieldComponent ForceField;
	UIslandShieldotronSidescrollerSettings ShieldotronSettings;
	float NextFlashTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShieldotronSettings = UIslandShieldotronSidescrollerSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
		ForceField = UIslandForceFieldComponent::GetOrCreate(Owner);
		ForceField.OnDepleting.AddUFunction(this, n"OnForceFieldDepleting");
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnForceFieldDepleting(AHazeActor Instigator)
	{
		// Kill off when down to a sliver of health.
		if (HealthComp.CurrentHealth < ShieldotronSettings.ForceFieldDepletedDamage)
			HealthComp.TakeDamage(ShieldotronSettings.ForceFieldDepletedDamage, EDamageType::Projectile, Instigator);
		DamageFlash::DamageFlashActor(Owner, 0.4, FLinearColor(1,1,1,0.1));
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		UIslandShieldotronEffectHandler::Trigger_OnStartDying(Owner);
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronStartDying(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronStartDying(Game::Mio, FIslandShieldotronPlayerEventData(Owner));

		UIslandShieldotronEffectHandler::Trigger_OnDeath(Owner);
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDeath(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDeath(Game::Mio, FIslandShieldotronPlayerEventData(Owner));
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Params)
	{
		if (ForceField.IsEnabled() && ForceField.IsReflectingBullets())
			return;
				
		UIslandShieldotronEffectHandler::Trigger_OnDamage(Owner, FIslandProjectileImpactParams(Params.ImpactLocation));
		HealthComp.TakeDamage(ShieldotronSettings.DefaultDamage * Params.ImpactDamageMultiplier, EDamageType::Projectile, Params.Player);
		if (NextFlashTime < Time::GameTimeSeconds)
		{
			DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor(0.5,0.5,0.5,0.1));
			NextFlashTime = Time::GameTimeSeconds + 0.1;
		}
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDamage(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDamage(Game::Mio, FIslandShieldotronPlayerEventData(Owner));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ShieldotronSettings.HurtReactionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::SmallHitReaction, EBasicBehaviourPriority::Medium, this, ShieldotronSettings.HurtReactionDuration);		
	}
}

