class UIslandPunchotronStunnedReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandForceFieldComponent ForceFieldComp;
	UIslandRedBlueImpactResponseComponent ResponseComp;
	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronSettings Settings;

	AAIIslandPunchotron Punchotron;

	bool bTriggerStunAnimation = false;
	float NextFlashTime = 0.0;		

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
		ForceFieldComp.OnDepleting.AddUFunction(this, n"OnForceFieldDepleting");
		HealthComp = UBasicAIHealthComponent ::Get(Owner);
		ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");		
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void OnForceFieldDepleting(AHazeActor Instigator)
	{
		// Kill off when down to a sliver of health.
		if (HealthComp.CurrentHealth < Settings.ForceFieldDepletedDamage)
			HealthComp.TakeDamage(Settings.ForceFieldDepletedDamage, EDamageType::Projectile, Instigator);
		DamageFlash::DamageFlashActor(Owner, 0.4, FLinearColor(1,1,1,0.1));

		bTriggerStunAnimation = true;
	}
	

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (!Owner.IsCapabilityTagBlocked(n"IslandForceField") && ForceFieldComp.IsEnabled() && ForceFieldComp.IsReflectingBullets())
			return;
		
		if (IsBlocked())
			return;

		UIslandPunchotronEffectHandler::Trigger_OnDamage(Owner, FIslandPunchotronProjectileImpactParams(Data.ImpactLocation));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronDamage(Game::Mio, FIslandPunchotronPlayerEventData(Owner));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronDamage(Game::Zoe, FIslandPunchotronPlayerEventData(Owner));

		HealthComp.TakeDamage(Settings.DefaultDamage * Data.ImpactDamageMultiplier, EDamageType::Projectile, Data.Player);		
		if (NextFlashTime < Time::GameTimeSeconds)
		{
			//DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor(0.1,0.1,0.1,0.01));
			NextFlashTime = Time::GameTimeSeconds + 0.1;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;		
		if (!bTriggerStunAnimation)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.StunnedDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::Stunned, EBasicBehaviourPriority::High, this, Settings.StunnedDuration);

		UIslandPunchotronEffectHandler::Trigger_OnStunned(Owner);
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronStunned(Game::Mio, FIslandPunchotronPlayerEventData(Owner));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronStunned(Game::Zoe, FIslandPunchotronPlayerEventData(Owner));

		// Reset attack state
		Punchotron.AttackDecalComp.Hide();
		Punchotron.AttackDecalComp.Reset();
		Punchotron.AttackTargetDecalComp.Hide();
		Punchotron.AttackTargetDecalComp.Reset();
		AttackComp.bIsAttacking = false;

		// Boss hack, set POI.
		AAIIslandPunchotronBoss Boss = Cast<AAIIslandPunchotronBoss>(Owner);
		if (Boss != nullptr)
		{
			FApplyPointOfInterestSettings POISettings;
			POISettings.Duration = 2.0;
			POISettings.RegainInputTime = 4.0;
			FHazePointOfInterestFocusTargetInfo FocusTarget;
			FocusTarget.SetFocusToActor(Owner);
			FocusTarget.SetWorldOffset(FVector(0,0,175));
			Game::Mio.ApplyPointOfInterest(this, FocusTarget, POISettings);
			Game::Zoe.ApplyPointOfInterest(this, FocusTarget, POISettings);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);
		Cooldown.Set(0.2);
		bTriggerStunAnimation = false;
	}

#if EDITOR
	UFUNCTION(DevFunction)
	private void TriggerStunBehaviour()
	{
		bTriggerStunAnimation = true;
	}

#endif
}
