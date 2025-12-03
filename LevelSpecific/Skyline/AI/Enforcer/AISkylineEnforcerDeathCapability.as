
class USkylineEnforcerDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Death");
	default CapabilityTags.Add(n"EnforcerDeath");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UTargetableOutlineComponent BladeOutline;
	UGravityWhipTargetComponent WhipTargetComp;
	UGravityWhipSlingAutoAimComponent WhipAutoAimComp;
	UGravityBladeGrappleComponent GrappleTarget;
	UHazeCharacterSkeletalMeshComponent Mesh;
	URagdollComponent RagdollComp;
	UHazeCapsuleCollisionComponent Collision;
	USkylineEnforcerDeathComponent DeathComp;
	USkylineEnforcerSettings Settings;

	float RemoteDeathTime = -1000.0;
	float DeathTime;
	bool bIsDying;
	bool bHasFinishedDying = false;
	bool bIsWhipDeath = false;
	float EffectsCompletionTime;
	private float EffectsCompletionDuration = 1.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		BladeOutline = UTargetableOutlineComponent::Get(Owner);
		DeathComp = USkylineEnforcerDeathComponent::GetOrCreate(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		WhipTargetComp = UGravityWhipTargetComponent::Get(Owner);
		WhipAutoAimComp = UGravityWhipSlingAutoAimComponent::Get(Owner);
		Settings = USkylineEnforcerSettings::GetSettings(Owner);

		GrappleTarget = UGravityBladeGrappleComponent::Get(Owner);

		AHazeCharacter CharOwner = Cast<AHazeCharacter>(Owner);
		Mesh = CharOwner.Mesh;
		Collision = CharOwner.CapsuleComponent;
		RagdollComp = URagdollComponent::GetOrCreate(Owner);
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
		if (bHasFinishedDying)
			return true;
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
		DeathTime = Time::GetGameTimeSeconds();
		bIsDying = true;
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		EffectsCompletionTime = EffectsCompletionDuration;

		BladeOutline.BlockOutline(this);

		// This should not use Owner as instigator! Should use this as instigator but we dare not change at this late stage
		if (WhipTargetComp != nullptr)
			WhipTargetComp.Disable(Owner);
		if (WhipAutoAimComp != nullptr)
			WhipAutoAimComp.Disable(Owner);
		if (GrappleTarget != nullptr)
			GrappleTarget.Disable(Owner);

		if (HealthComp.LastDamageType == EDamageType::MeleeSharp)
		{
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityBladeHitReactionDeath, EBasicBehaviourPriority::Maximum, this);
			bIsWhipDeath = false;
			UGravityBladeCombatEventHandler::Trigger_OnStartedKillingEnemy(Game::Mio, FGravityBladeKillData(Owner));
		}
		else
		{
			bIsWhipDeath = true;
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhipDeath, EBasicBehaviourPriority::Maximum, this);
		}

		/* For testing purposes we do this in the AnimInstance
		if (Time::GetGameTimeSince(RemoteDeathTime) > 4.0)
			UBasicAIDamageEffectHandler::Trigger_OnDeath(Owner);
		*/
		// Do not leave team here, we stay in team until endplay
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{			
		Owner.AddActorDisable(this);
		RagdollComp.ClearRagdoll(Mesh, Collision);
		RagdollComp.bAllowRagdoll.Clear(this);
		DeathComp.RagdollForce.Reset();

		if (!HasControl())
		{
			if (bHasFinishedDying)
			{
				// If animation finished on remote before crumb deactivation, remove blocks
				// Owner.RemoveActorVisualsBlock(this);
				Owner.RemoveActorCollisionBlock(this);

				if (WhipTargetComp != nullptr)
					WhipTargetComp.Enable(Owner);
				if (WhipAutoAimComp != nullptr)
					WhipAutoAimComp.Enable(Owner);
				if (GrappleTarget != nullptr)
					GrappleTarget.Enable(Owner);
			}
			else
			{
				// Crumb deactivation occurred before animation finished
				UEnforcerEffectHandler::Trigger_OnUnspawn(Owner);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(RagdollComp.IsRagdollAllowed() && !RagdollComp.bIsRagdolling)
		{
			RagdollComp.ApplyRagdoll(Mesh, Collision);
			FVector Velocity = Owner.ActorVelocity;
			if(Velocity.IsNearlyZero())
				Velocity = -Owner.ActorForwardVector;
			RagdollComp.ApplyRagdollImpulse(Mesh, FRagdollImpulse(ERagdollImpulseType::WorldSpace, DeathComp.RagdollForce.Get(Velocity), Mesh.GetSocketLocation(n"Spine2"), n"Spine2"));
			UEnforcerEffectHandler::Trigger_OnRagdoll(Owner);
			EffectsCompletionTime = ActiveDuration + EffectsCompletionDuration;
		}

		if (ShouldFinishDying())
		{
			UEnforcerEffectHandler::Trigger_OnUnspawn(Owner);
			
			bHasFinishedDying = true;
			// if remote side completes animation before crumb deactivation, turn off stuff
			if (!HasControl())
			{
				// Owner.AddActorVisualsBlock(this);
				Owner.AddActorCollisionBlock(this);
			}
		}
		
	}

	private bool ShouldFinishDying()
	{
		if(bHasFinishedDying)
			return false;

		//* Let animation decide when death is completeFEnforcerEffectOnDeathDataFEnforcerEffectOnDeathData
		if(!AnimComp.IsFinished(LocomotionFeatureAISkylineTags::GravityBladeHitReactionDeath, NAME_None))
			return false;

		if(bIsWhipDeath && ActiveDuration < Settings.GravityWhipMinDeathDuration)
			return false;

		if(ActiveDuration < EffectsCompletionTime)
			return false;

		return true;
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Owner.RemoveActorDisable(this);
		if(bIsDying && Owner.IsCapabilityTagBlocked(BasicAITags::Behaviour))
			Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		
		if (bIsDying)
		{
			BladeOutline.UnblockOutline(this);
		}

		bIsDying = false;
		bHasFinishedDying = false;
		
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRemotePreDeath()
	{
		if (HasControl())
			return; // Remote side only

		RemoteDeathTime = Time::GameTimeSeconds;
		UBasicAIDamageEffectHandler::Trigger_OnDeath(Owner);
	}
}