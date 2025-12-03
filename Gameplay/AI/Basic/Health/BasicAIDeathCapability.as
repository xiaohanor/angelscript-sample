
class UBasicAIDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::Death);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;	

	bool bHasPerformedRemoteDeath = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
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
		HealthComp.TriggerStartDying();
		if (!HasControl()) 
			HealthComp.RemoteDie();
		HealthComp.OnDie.Broadcast(Owner);
		Owner.AddActorDisable(this);

		if (!bHasPerformedRemoteDeath)
			UBasicAIDamageEffectHandler::Trigger_OnDeath(Owner);

		// Do not leave team here, we stay in team until endplay
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
		UBasicAIDamageEffectHandler::Trigger_OnDeath(Owner);
		Owner.AddActorVisualsBlock(this);
	}
}