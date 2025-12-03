class UIslandPunchotronSidescrollerStunnedReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	default CapabilityTags.Add(n"Stunned");

	UIslandForceFieldComponent ForceFieldComp;
	UIslandRedBlueImpactResponseComponent ResponseComp;
	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronSettings Settings;

	AAIIslandPunchotron Punchotron;

	TPerPlayer<float> BufferedDamageAmount;
	float NextTakeDamageCheckTimeStamp;
	const float NetMaxHitsPerSecond = 30.0;
	
	float NextFlashTime = 0.0;

	bool bTriggerStunAnimation = false;

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
		if (ForceFieldComp.IsEnabled() && ForceFieldComp.IsReflectingBullets())
			return;

		// Beating on a dead horse?
		if (HealthComp.IsDead())
			return;

		UIslandPunchotronEffectHandler::Trigger_OnDamage(Owner, FIslandPunchotronProjectileImpactParams(Data.ImpactLocation));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronDamage(Game::Mio, FIslandPunchotronPlayerEventData(Owner));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronDamage(Game::Zoe, FIslandPunchotronPlayerEventData(Owner));

		if (NextFlashTime < Time::GameTimeSeconds)
		{
			DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor(0.5,0.5,0.5,0.1));
			NextFlashTime = Time::GameTimeSeconds + 0.1;
		}

		if (!Data.Player.HasControl())
			return;
		
		if (!Network::IsGameNetworked())
			HealthComp.TakeDamage(Settings.SidescrollerBulletDamage * Data.ImpactDamageMultiplier, EDamageType::Projectile, Data.Player);
		else
			BufferedDamageAmount[Data.Player] += Settings.SidescrollerBulletDamage * Data.ImpactDamageMultiplier;		
	}



	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Buffered damage dealing is only relevant for a networked game.
		if (!Network::IsGameNetworked())
			return;

		if (NextTakeDamageCheckTimeStamp > Time::GameTimeSeconds)
			return;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (BufferedDamageAmount[Player] > 0) // this will only be nonzero on the player control side.
			{
				HealthComp.TakeDamage(BufferedDamageAmount[Player], EDamageType::Projectile, Player);
				BufferedDamageAmount[Player] = 0.0;
				NextTakeDamageCheckTimeStamp = Time::GameTimeSeconds + 1.0 / NetMaxHitsPerSecond;
			}
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
		if (ActiveDuration > Settings.SidescrollerStunnedDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::Stunned, EBasicBehaviourPriority::High, this, Settings.SidescrollerStunnedDuration);

		UIslandPunchotronEffectHandler::Trigger_OnStunned(Owner);
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronStunned(Game::Mio, FIslandPunchotronPlayerEventData(Owner));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronStunned(Game::Zoe, FIslandPunchotronPlayerEventData(Owner));

		// Reset attack state
		AttackComp.bIsAttacking = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);		
		Cooldown.Set(0.2);
		bTriggerStunAnimation = false;
	}

}