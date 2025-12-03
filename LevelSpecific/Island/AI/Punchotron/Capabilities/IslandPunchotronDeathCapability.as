
class UIslandPunchotronDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::Death);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UIslandPunchotronSettings Settings;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UIslandRedBlueTargetableComponent TargetableComp;
	UIslandRedBlueImpactResponseComponent DamageResponseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		TargetableComp = UIslandRedBlueTargetableComponent::Get(Owner);
		DamageResponseComp = UIslandRedBlueImpactResponseComponent::Get(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);

		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
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
		if (ActiveDuration > Settings.DeathDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (AnimComp != nullptr)
			AnimComp.RequestFeature(FeatureTagIslandPunchotron::Death, EBasicBehaviourPriority::Maximum, this, Settings.DeathDuration);

		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.BlockCapabilities(n"IslandForceField", this);
		if (TargetableComp != nullptr)
			TargetableComp.Disable(this);

		DamageResponseComp.BlockImpactForPlayer(Game::Mio, this);
		DamageResponseComp.BlockImpactForPlayer(Game::Zoe, this);

		UIslandPunchotronEffectHandler::Trigger_OnStartDying(Owner);
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronStartDying(Game::Mio, FIslandPunchotronPlayerEventData(Owner));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronStartDying(Game::Zoe, FIslandPunchotronPlayerEventData(Owner));

		Owner.AddActorCollisionBlock(this);

		HealthComp.TriggerStartDying();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!HasControl()) 
			HealthComp.RemoteDie();
		HealthComp.OnDie.Broadcast(Owner);
		Owner.AddActorDisable(this);

		UIslandPunchotronEffectHandler::Trigger_OnDeath(Owner);
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronDeath(Game::Mio, FIslandPunchotronPlayerEventData(Owner));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronDeath(Game::Zoe, FIslandPunchotronPlayerEventData(Owner));

		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.UnblockCapabilities(n"IslandForceField", this);
		if (TargetableComp != nullptr)
			TargetableComp.Enable(this);

		DamageResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		DamageResponseComp.UnblockImpactForPlayer(Game::Zoe, this);

		Owner.RemoveActorCollisionBlock(this);

		// Do not leave team here, we stay in team until endplay
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Owner.RemoveActorDisable(this);
	}
	
}