class UIslandAttackShipPilotDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::Death);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UIslandAttackShipSettings Settings;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UIslandRedBlueTargetableComponent TargetableComp;
	UIslandRedBlueImpactResponseComponent ResponseComp;

	bool bHasPerformedRemoteDeath = false;
	bool bHasBlockedCompound = false;

	AAIIslandAttackShip AttackShip;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		TargetableComp = UIslandRedBlueTargetableComponent::Get(Owner);
		Settings = UIslandAttackShipSettings::GetSettings(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		ResponseComp = UIslandRedBlueImpactResponseComponent::Get(Owner);
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");

		AttackShip = Cast<AAIIslandAttackShip>(Owner);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		if (bHasPerformedRemoteDeath)
			Owner.RemoveActorVisualsBlock(this);
		bHasPerformedRemoteDeath = false;
		AttackShip.Mesh.SetHiddenInGame(false);
		TargetableComp.Enable(this);
		if (bHasBlockedCompound)
			Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		bHasBlockedCompound = false;
		AttackShip.bHasPilotDied = false;
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Params)
	{
		UIslandShieldotronEffectHandler::Trigger_OnDamage(Owner, FIslandProjectileImpactParams(Params.ImpactLocation));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDamage(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronDamage(Game::Mio, FIslandShieldotronPlayerEventData(Owner));
		float Damage = Settings.DefaultDamage * Params.ImpactDamageMultiplier;
		HealthComp.TakeDamage(Damage, EDamageType::Projectile, Params.Player);
	}
	float NextFlashTime = 0.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HealthComp.IsDead())
			return false;
		if (AttackShip.bHasPilotDied) // already died.
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
		bHasBlockedCompound = true;
		TargetableComp.Disable(this);
		AttackShip.bHasPilotDied = true;

		// Mark owner as the last dying team member. Important for when all team members are killed in the same tick.
		if (!AttackShip.CurrentManager.HasLivingTeamMember(AttackShip))
			AttackShip.CurrentManager.SetMarkLastTeamMember(AttackShip);
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
			AttackShip.Mesh.SetHiddenInGame(true);
		}

		// Do not leave team here, we stay in team until endplay
		AttackShip.OnPilotDied();
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
		AttackShip.Mesh.SetHiddenInGame(true);
	}

}