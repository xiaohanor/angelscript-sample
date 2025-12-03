class UPrisonGuardCommonDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Death");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	AHazeCharacter CharOwner;
	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UPrisonGuardSettings Settings;
	float RemoteDeathTime = -1000.0;
	FName DefaultCollisionProfile;
	FTransform DefaultMeshRelativeTransform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CharOwner = Cast<AHazeCharacter>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		Settings = UPrisonGuardSettings::GetSettings(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		DefaultCollisionProfile = CharOwner.CapsuleComponent.CollisionProfileName;
		DefaultMeshRelativeTransform = CharOwner.Mesh.RelativeTransform;
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
		// Unconscious while life is slipping away
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);

		HealthComp.TriggerStartDying();
		if (!HasControl()) 
			HealthComp.RemoteDie();
		HealthComp.OnDie.Broadcast(Owner);

		if (AnimComp != nullptr)
			AnimComp.RequestFeature(LocomotionFeatureAITags::Death, SubTagAIDeath::Default, EBasicBehaviourPriority::Maximum, this);

		if (Time::GetGameTimeSince(RemoteDeathTime) > 4.0)
			UBasicAIDamageEffectHandler::Trigger_OnDeath(Owner);

		// You only die once
		Owner.BlockCapabilities(n"Death", this);

		Owner.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// The rapture!
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		Owner.UnblockCapabilities(n"Death", this);
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
		if (AnimComp != nullptr)
			AnimComp.RequestFeature(LocomotionFeatureAITags::Death, SubTagAIDeath::Default, EBasicBehaviourPriority::Maximum, this);

		UBasicAIDamageEffectHandler::Trigger_OnDeath(Owner);
	}
}
