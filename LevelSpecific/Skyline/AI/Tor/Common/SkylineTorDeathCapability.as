
class USkylineTorDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::Death);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;	
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorExposedComponent ExposedComp;
	USkylineTorOpportunityAttackComponent OpportunityAttackComp;
	URagdollComponent RagdollComp;
	USkylineTorHoldHammerComponent HoldHammerComp;

	bool bHasPerformedRemoteDeath = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		ExposedComp = USkylineTorExposedComponent::GetOrCreate(Owner);
		OpportunityAttackComp = USkylineTorOpportunityAttackComponent::GetOrCreate(Owner);
		RagdollComp = URagdollComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::Get(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.Phase != ESkylineTorPhase::Dead)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.Phase != ESkylineTorPhase::Dead)
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

		// Owner.AddActorDisable(this);
		Owner.BlockCapabilities(n"Behaviour", this);
		AnimComp.RequestFeature(FeatureTagSkylineTor::Death, NAME_None, EBasicBehaviourPriority::High, this);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		RagdollComp.ApplyRagdoll(Character.Mesh, Character.CapsuleComponent);
		RagdollComp.ApplyRagdollImpulse(Character.Mesh, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(0, -5000, 500), FVector::ZeroVector, n"LeftForeArm"));
		RagdollComp.ApplyRagdollImpulse(Character.Mesh, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(0, 5000, 500), FVector::ZeroVector, n"RightForeArm"));
		RagdollComp.ApplyRagdollImpulse(Character.Mesh, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(-10000, 0, 2000), FVector::ZeroVector, n"Spine2"));

		if (!bHasPerformedRemoteDeath)
			UBasicAIDamageEffectHandler::Trigger_OnDeath(Owner);

		// Do not leave team here, we stay in team until endplay
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		RagdollComp.ClearRagdoll(Character.Mesh, Character.CapsuleComponent);
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