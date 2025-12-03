
class UIslandWalkerDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Death");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UIslandWalkerLegsComponent LegsComp;
	float RemoteDeathTime = -1000.0;
	bool bHasDied;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);

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
		if (!HealthComp.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HealthComp.TriggerStartDying();
		if (!HasControl()) 
			HealthComp.RemoteDie();
		HealthComp.OnDie.Broadcast(Owner);	
		Owner.BlockCapabilities(n"Behaviour", this);
		bHasDied = true;
		RequestAnims();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		if(bHasDied)
			Owner.UnblockCapabilities(n"Behaviour", this);
		bHasDied = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRemotePreDeath()
	{
		if (HasControl())
			return; // Remote side only

		RemoteDeathTime = Time::GameTimeSeconds;
		UBasicAIDamageEffectHandler::Trigger_OnDeath(Owner);
		RequestAnims();
	}

	private void RequestAnims()
	{
		if (LegsComp.UnbalancedDirection == EIslandWalkerUnbalancedDirection::Forward)
			AnimComp.RequestFeature(FeatureTagWalker::Fall, SubTagWalkerFall::Forward, EBasicBehaviourPriority::Maximum, this);

		if (LegsComp.UnbalancedDirection == EIslandWalkerUnbalancedDirection::Left)
			AnimComp.RequestFeature(FeatureTagWalker::Fall, SubTagWalkerFall::Left, EBasicBehaviourPriority::Maximum, this);

		if (LegsComp.UnbalancedDirection == EIslandWalkerUnbalancedDirection::Right)
			AnimComp.RequestFeature(FeatureTagWalker::Fall, SubTagWalkerFall::Right, EBasicBehaviourPriority::Maximum, this);
	}
}