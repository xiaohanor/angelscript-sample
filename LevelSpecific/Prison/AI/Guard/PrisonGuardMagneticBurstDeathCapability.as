class UPrisonGuardMagneticBurstDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Death");

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 50;

	AHazeCharacter CharOwner;
	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UMagneticFieldResponseComponent ResponseComp;
	UPrisonGuardSettings Settings;
	FName DefaultCollisionProfile;
	FTransform DefaultMeshRelativeTransform;
	FVector MagneticImpulse = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CharOwner = Cast<AHazeCharacter>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		ResponseComp = UMagneticFieldResponseComponent::Get(Owner);
		Settings = UPrisonGuardSettings::GetSettings(Owner);

		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		ResponseComp.OnBurst.AddUFunction(this, n"OnBurst");

		DefaultCollisionProfile = CharOwner.CapsuleComponent.CollisionProfileName;
		DefaultMeshRelativeTransform = CharOwner.Mesh.RelativeTransform;
	}

	UFUNCTION()
	private void OnBurst(FMagneticFieldData Data)
	{
		// Save magnetic impulse in case this kills us (damage is taken in stunned behaviour)
		for(const FMagneticFieldComponentData& ComponentData : Data.ComponentDatas)
		{
			FVector PushDir = (ComponentData.ForceAffectPoint - Data.ForceOrigin).GetSafeNormal();
			MagneticImpulse += (PushDir * Settings.MagneticPushForce + Owner.ActorUpVector * Settings.MagneticPushUpwardsBoost) * ComponentData.ProximityFraction;
		}
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

		// You only die once
		Owner.BlockCapabilities(n"Death", this);

		FPrisonGuardDamageParams Params;
		Params.Direction = (Owner.ActorCenterLocation - Game::Zoe.ActorLocation).GetSafeNormal();	
		UPrisonGuardEffectHandler::Trigger_OnDeath(Owner, Params);

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
		MagneticImpulse = FVector::ZeroVector;
	}
}
