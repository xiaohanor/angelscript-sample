
class USummitCrystalSkullTailSmashCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Death");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UAdultDragonTailSmashModeResponseComponent TailResponseComponent;
	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	USummitCrystalSkullArmourComponent ArmourComp;
	float RemoteDeathTime = -1000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailResponseComponent = UAdultDragonTailSmashModeResponseComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		ArmourComp = USummitCrystalSkullArmourComponent::Get(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		TailResponseComponent.OnHitBySmashMode.AddUFunction(this, n"OnHitByTailDragon");
	}

	UFUNCTION()
	private void OnHitByTailDragon(FTailSmashModeHitParams Params)
	{
		// Can't be smashed when armoured
		if ((ArmourComp != nullptr) && ArmourComp.HadArmour(1.0))
			return;

		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::MeleeBlunt, Params.PlayerInstigator);
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

		if (AnimComp != nullptr)
			AnimComp.RequestFeature(LocomotionFeatureAITags::Death, SubTagAIDeath::Default, EBasicBehaviourPriority::Maximum, this);

		if (Time::GetGameTimeSince(RemoteDeathTime) > 4.0)
			USummitCrystalSkullEventHandler::Trigger_OnSmashed(Owner);

		// Do not leave team here, we stay in team until endplay
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Owner.RemoveActorDisable(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRemotePreDeath()
	{
		if (HasControl())
			return; // Remote side only

		RemoteDeathTime = Time::GameTimeSeconds;
		USummitCrystalSkullEventHandler::Trigger_OnSmashed(Owner);
	}
}