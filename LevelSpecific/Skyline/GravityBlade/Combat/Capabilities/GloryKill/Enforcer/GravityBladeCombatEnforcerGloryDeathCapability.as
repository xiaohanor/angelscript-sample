class UGravityBladeCombatEnforcerGloryDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GloryKill");
	default CapabilityTags.Add(BasicAITags::Death);

	// Play glory kill anim and move somewhat in sync with player while using collision
	// ...GloryDeathSyncMeshCapability will sync mesh perfectly.
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20; // Before any other AI movement

	// Crumb synced, will sync up values needed by sync capability so we won't ned extra networking
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UGravityBladeCombatEnforcerGloryDeathComponent GloryDeathComp;
	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAICharacterMovementComponent MoveComp;
	UGravityBladeCombatUserComponent KillerComp;
	UHazeCharacterSkeletalMeshComponent Mesh;
	UBasicAIDestinationComponent DestinationComp;
	UGravityBladeCombatTargetComponent TargetComp;
	URagdollComponent RagdollComp;
	UHazeCapsuleCollisionComponent Collision;
	UEnforcerDamageComponent NormalDamageComp;

	UGravityWhipTargetComponent WhipTargetComp;
	UGravityWhipSlingAutoAimComponent WhipAutoAimComp;

	USkylineEnforcerSettings Settings;

	USteppingMovementData Movement;

	bool bWasDying;
	bool bHasFinishedDying = false;
	float PrevRootMotionTime = 0.0;
	bool bIsRagdolled = false;
	FName OriginalCollisionProfileName;
	float DamagePerHit = 0.0;
	int NumHitsLeft = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryDeathComp = UGravityBladeCombatEnforcerGloryDeathComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner); 
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		TargetComp = UGravityBladeCombatTargetComponent::Get(Owner);

		AHazeCharacter CharOwner = Cast<AHazeCharacter>(Owner);
		Mesh = CharOwner.Mesh;
		Collision = CharOwner.CapsuleComponent;
		WhipTargetComp = UGravityWhipTargetComponent::Get(Owner);
		WhipAutoAimComp = UGravityWhipSlingAutoAimComponent::Get(Owner);
		RagdollComp = URagdollComponent::GetOrCreate(Owner);
		NormalDamageComp = UEnforcerDamageComponent::Get(Owner);
		Settings = USkylineEnforcerSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		UGravityBladeCombatResponseComponent::Get(Owner).OnHit.AddUFunction(this, n"OnBladeHit");	
	}

	AHazePlayerCharacter GetKiller(UGravityBladeCombatUserComponent CombatComp) const
	{
		if (CombatComp.Owner == Game::Mio) 
			return Game::Mio;
		return Game::Zoe;
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (!IsActive())
			return;
		AHazePlayerCharacter Attacker = GetKiller(CombatComp);
		if (DamagePerHit < SMALL_NUMBER)
		{
			// Find damage from player animation notifies
			TArray<FHazePlayingAnimationData> Animations;
			Attacker.Mesh.GetCurrentlyPlayingAnimations(Animations);
			for (FHazePlayingAnimationData AnimData : Animations)
			{
				if (AnimData.Sequence == nullptr)
					continue;
				TArray<FHazeAnimNotifyStateGatherInfo> Hits;
				if (!AnimData.Sequence.GetAnimNotifyStateTriggerTimes(UAnimNotifyGravityBladeHitWindow, Hits))
					continue;
				// Deal weak damage for all hits but the last
				DamagePerHit = (HealthComp.CurrentHealth * 0.5) / Hits.Num();
				NumHitsLeft = Hits.Num();
				break;
			}
		}

		NumHitsLeft--;
		if (NumHitsLeft < 1)
		{
			// Last hit is killing blow
			DamagePerHit = HealthComp.CurrentHealth; 
			HealthComp.TriggerStartDying();
		}
		HealthComp.TakeDamage(DamagePerHit, HitData.DamageType, Attacker);
		// DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor::White);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (!GloryDeathComp.bShouldGloryDie)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FEnforcerGloryDeathDeactivationParams& OutParams) const
	{
		if (!HealthComp.HasStartedDying())
		{
			if(KillerComp.bGloryKillInterrupted || DestinationComp.bHasPerformedMovement)
			{
				OutParams.bWasInterrupted = true;
				return true;
			}
		}

		if(ActiveDuration >= GloryDeathComp.GloryDeathDuration + Settings.GloryKillCorpseDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		TargetComp.Disable(this);
		GloryDeathComp.bShouldGloryDie = true; // Synced here for use by local sync mesh capability
		KillerComp = UGravityBladeCombatUserComponent::Get(Game::Mio);
		NormalDamageComp.bIgnoreBladeHitDamage = true;
		DamagePerHit = 0.0; // Unknown, will be set at first hit (if no hits then killing damage is dealt when deactivating)

		bWasDying = true;
		Owner.BlockCapabilities(n"EnforcerDeath", this);
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);

		if (WhipTargetComp != nullptr)
			WhipTargetComp.Disable(Owner);
		if (WhipAutoAimComp != nullptr)
			WhipAutoAimComp.Disable(Owner);

		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GloryDeath, EBasicBehaviourPriority::Maximum, this);
		UEnforcerEffectHandler::Trigger_OnGloryDeathStart(Owner);
		UGravityBladeCombatEventHandler::Trigger_OnStartedGloryKilling(GetKiller(KillerComp), FGravityBladeKillData(Owner));
		UGravityBladeCombatEventHandler::Trigger_OnStartedKillingEnemy(GetKiller(KillerComp), FGravityBladeKillData(Owner));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FEnforcerGloryDeathDeactivationParams Params)
	{
		// Allow normal damage
		NormalDamageComp.bIgnoreBladeHitDamage = false;
		GloryDeathComp.bShouldGloryDie = false;
		RagdollComp.ClearRagdoll(Mesh, Collision);

		if (Params.bWasInterrupted)
		{
			TargetComp.Enable(this);
			AnimComp.Reset();
			OnRespawn();
			if (WhipTargetComp != nullptr)
				WhipTargetComp.Enable(Owner);
			if (WhipAutoAimComp != nullptr)
				WhipAutoAimComp.Enable(Owner);
			return;
		} 

		if (!HealthComp.HasStartedDying())
			HealthComp.TriggerStartDying();

		FEnforcerEffectOnDeathData Data;
		Data.DeathType = EEnforcerDeathType::GloryDeath;
		UEnforcerEffectHandler::Trigger_OnDeath(Owner, Data);

		TargetComp.Enable(this);
		if(!HealthComp.IsDead())
			HealthComp.TakeDamage(HealthComp.CurrentHealth, EDamageType::MeleeSharp, GloryDeathComp.KillerPlayer);

		HealthComp.OnDie.Broadcast(Owner);

		Owner.RemoveActorCollisionBlock(this);
		Owner.AddActorDisable(this);
		
		if (!HasControl())
		{
			if (bHasFinishedDying)
			{
				// If animation finished on remote before crumb deactivation, remove blocks
				// Owner.RemoveActorVisualsBlock(this);
				if (WhipTargetComp != nullptr)
					WhipTargetComp.Enable(Owner);
				if (WhipAutoAimComp != nullptr)
					WhipAutoAimComp.Enable(Owner);
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
			HealthComp.TriggerStartDying();
			HealthComp.TakeDamage(HealthComp.CurrentHealth, EDamageType::MeleeSharp, GetKiller(KillerComp));
			RagdollComp.ApplyRagdoll(Mesh, Collision);
			UEnforcerEffectHandler::Trigger_OnRagdoll(Owner);
		}

		if(!RagdollComp.bIsRagdolling)
		{
			if (!ensure(MoveComp.PrepareMove(Movement)))
				return;

			if (HasControl())
			{
				if (KillerComp.bGloryKillActive)
				{
					// Move to where our mesh is (this will be one frame behind, since mesh is moved at end of frame)
					Movement.AddDeltaFromMoveToPositionWithCustomVelocity(Mesh.WorldLocation, FVector::ZeroVector); 
					Movement.SetRotation(Mesh.WorldRotation);
				}
				else 
				{
					// Player has moved along, use regular movement with the root motion we get from the glory kill anim
					FTransform RootMotion = GetRootmotionDelta(DeltaTime);
					Movement.AddDelta(RootMotion.Translation);
					Movement.SetRotation(Owner.ActorQuat * RootMotion.Rotation);
				}
			}
			else
			{
				// Remote (note that this will set zero velocity)
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
			DestinationComp.bHasPerformedMovement = true;
		}

		if (!bHasFinishedDying && AnimComp.IsFinished(LocomotionFeatureAISkylineTags::GloryDeath, NAME_None))
		{
			UEnforcerEffectHandler::Trigger_OnUnspawn(Owner);
			
			bHasFinishedDying = true;
			
			// if remote side completes animation before crumb deactivation, turn off stuff
			// if (!HasControl())
			// {
			// 	Owner.AddActorVisualsBlock(this);
			// }
		}

		PrevRootMotionTime += DeltaTime;
	}

	FTransform GetRootmotionDelta(float DeltaTime)
	{
		FTransform FullRootMotion;
		TArray<FHazePlayingAnimationData> Animations;
		Mesh.GetCurrentlyPlayingAnimations(Animations);
		for (FHazePlayingAnimationData AnimData : Animations)
		{
			if (AnimData.Sequence == nullptr)
				continue;
			FHazeLocomotionTransform AnimRootMotion;		
			if (!AnimData.Sequence.ExtractRootMotion(PrevRootMotionTime, PrevRootMotionTime + DeltaTime, AnimRootMotion))
				continue;
			FullRootMotion *= FTransform(AnimRootMotion.DeltaRotation, AnimRootMotion.DeltaTranslation);
		}
		return FullRootMotion;
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Owner.RemoveActorDisable(this);
		if(bWasDying)
		{
			Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
			Owner.UnblockCapabilities(n"EnforcerDeath", this);
		}
		bWasDying = false;
		bHasFinishedDying = false;
	}
}

struct FEnforcerGloryDeathDeactivationParams
{
	bool bWasInterrupted = false;
}