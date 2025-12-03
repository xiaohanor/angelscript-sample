class UCoastPoltroonDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Death");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	float RemoteDeathTime = -1000.0;
	float DeathTime;
	bool bIsDying;
	bool bHasFinishedDying = false;
	float DirZ = 0.75;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
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

		AnimComp.RequestFeature(CoastPoltroonFeatureTag::Death, EBasicBehaviourPriority::Maximum, this);
		UCoastPoltroonEffectHandler::Trigger_OnDeath(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{			
			Owner.AddActorDisable(this);
			
			if (!HasControl())
			{
				if (bHasFinishedDying)
				{
					// If animation finished on remote before crumb deactivation, remove blocks
					Owner.RemoveActorVisualsBlock(this);
					Owner.RemoveActorCollisionBlock(this);
				}
				else
				{
					// Crumb deactivation occurred before animation finished
					// UCoastPoltroonEffectHandler::Trigger_OnDeath(Owner);
				}
			}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Right = Owner.AttachParentActor.ActorRightVector;
		float Dot = Owner.AttachParentActor.ActorRightVector.DotProduct(Owner.ActorLocation - Owner.AttachParentActor.ActorLocation);
		if(Dot < 0)
			Right *= -1;
		FVector Dir = (Right + (Owner.AttachParentActor.ActorForwardVector * -1)).GetSafeNormal();
		DirZ -= DeltaTime * 0.75;
		Dir.Z = DirZ;
		
		FHitResult Dummy;
		Owner.AddActorWorldOffset(Dir * 2500 * DeltaTime, false, Dummy, false);
		Owner.AddActorLocalRotation(FRotator(300, 300, 0) * DeltaTime);

		if (!bHasFinishedDying && ActiveDuration > 3)
		{			
			bHasFinishedDying = true;
			// if remote side completes animation before crumb deactivation, turn off stuff
			if (!HasControl())
			{
				Owner.AddActorVisualsBlock(this);
				Owner.AddActorCollisionBlock(this);
			}
		}
		
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Owner.RemoveActorDisable(this);
		if(bIsDying && Owner.IsCapabilityTagBlocked(BasicAITags::Behaviour))
			Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
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