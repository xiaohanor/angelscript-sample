
class UIslandPunchotronSidescrollerDeathCapability : UHazeCapability
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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.BlockCapabilities(n"IslandForceField", this);
		if (TargetableComp != nullptr)
			TargetableComp.Disable(this);

		DamageResponseComp.BlockImpactForPlayer(Game::Mio, this);
		DamageResponseComp.BlockImpactForPlayer(Game::Zoe, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!HasControl()) 
			HealthComp.RemoteDie();

		UIslandPunchotronEffectHandler::Trigger_OnDeath(Owner);
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronSidescrollerDeath(Game::Mio, FIslandPunchotronSidescrollerDeathPlayerEventData(Owner, HealthComp.LastAttacker));
		UIslandPunchotronPlayerEffectHandler::Trigger_OnPunchotronSidescrollerDeath(Game::Zoe, FIslandPunchotronSidescrollerDeathPlayerEventData(Owner, HealthComp.LastAttacker));
		
		HealthComp.OnDie.Broadcast(Owner);
		Owner.AddActorDisable(this);

		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.UnblockCapabilities(n"IslandForceField", this);
		if (TargetableComp != nullptr)
			TargetableComp.Enable(this);

		DamageResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		DamageResponseComp.UnblockImpactForPlayer(Game::Zoe, this);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Owner.RemoveActorDisable(this);
	}
	
}