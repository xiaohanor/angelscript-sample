
class UIslandJetpackShieldotronDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::Death);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UIslandJetpackShieldotronSettings JetpackSettings;
	UIslandShieldotronSettings Settings;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UIslandRedBlueTargetableComponent TargetableComp;
	UIslandRedBlueImpactResponseComponent ResponseComp;
	UIslandForceFieldComponent ForceField;
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;

	bool bHasPerformedRemoteDeath = false;
	float NextFlashTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		TargetableComp = UIslandRedBlueTargetableComponent::Get(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
		JetpackSettings = UIslandJetpackShieldotronSettings::GetSettings(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		ForceField = UIslandForceFieldComponent::GetOrCreate(Owner);
		ForceField.OnDepleting.AddUFunction(this, n"OnForceFieldDepleting");
	
		ForceFieldBubbleComp = UIslandForceFieldBubbleComponent::GetOrCreate(Owner);		

		ResponseComp = UIslandRedBlueImpactResponseComponent::Get(Owner);
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
	}


	UFUNCTION()
	private void OnForceFieldDepleting(AHazeActor Instigator)
	{
		// Kill off when down to a sliver of health.
		if (HealthComp.CurrentHealth < Settings.ForceFieldDepletedDamage)
			HealthComp.TakeDamage(Settings.ForceFieldDepletedDamage, EDamageType::Projectile, Instigator);
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Params)
	{
		if (ForceField.IsEnabled() && ForceField.IsReflectingBullets())
			return;
		
		if (ForceFieldBubbleComp.IsEnabled() && !ForceFieldBubbleComp.IsDepleted())
			return;

		UIslandShieldotronEffectHandler::Trigger_OnDamage(Owner, FIslandProjectileImpactParams(Params.ImpactLocation));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDamage(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDamage(Game::Mio, FIslandShieldotronPlayerEventData(Owner));
		HealthComp.TakeDamage(JetpackSettings.DefaultDamage * Params.ImpactDamageMultiplier, EDamageType::Projectile, Params.Player);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HealthComp.IsDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.BlockCapabilities(n"IslandForceField", this);
		TargetableComp.Disable(this);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HealthComp.TriggerStartDying();
		if (!HasControl()) 
			HealthComp.RemoteDie();
		HealthComp.OnDie.Broadcast(Owner);

		if (!bHasPerformedRemoteDeath)
		{
			UIslandShieldotronEffectHandler::Trigger_OnDeath(Owner);
			UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDeath(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
			UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDeath(Game::Mio, FIslandShieldotronPlayerEventData(Owner));
						
			// This is needed by VO:
			UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronStartDying(Game::Mio, FIslandShieldotronPlayerEventData(Owner));
			UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronStartDying(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
		}

		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.UnblockCapabilities(n"IslandForceField", this);
		TargetableComp.Enable(this);

		// Do not leave team here, we stay in team until endplay
		Owner.AddActorDisable(this);
	}
	
	UFUNCTION()
	private void OnRespawn()
	{
		if (bHasPerformedRemoteDeath)
			Owner.RemoveActorVisualsBlock(this);
		bHasPerformedRemoteDeath = false;
		Owner.RemoveActorDisable(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRemotePreDeath()
	{
		if (HasControl())
			return; // Remote side only

		bHasPerformedRemoteDeath = true;
		UIslandShieldotronEffectHandler::Trigger_OnDeath(Owner);
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDeath(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDeath(Game::Mio, FIslandShieldotronPlayerEventData(Owner));

		// This is needed by VO:
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronStartDying(Game::Mio, FIslandShieldotronPlayerEventData(Owner));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronStartDying(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
		Owner.AddActorVisualsBlock(this);
	}

}