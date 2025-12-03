class USanctuaryWeeperDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Death");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	USanctuaryWeeperSettings Settings;
	UHazeCharacterSkeletalMeshComponent Mesh;
	float DeathTime;
	bool bIsDying;
	bool bHasFinishedDying;
	FName DeathFeature;
	float DeathAnimDoneTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		Settings = USanctuaryWeeperSettings::GetSettings(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;

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
		if (bHasFinishedDying && (Time::GetGameTimeSince(DeathAnimDoneTime) > Settings.DeathAfterAnimationDuration))
			return true;
		if (ActiveDuration > 20.0)
			return true; // Backup in case we fail to find anim
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HealthComp.TriggerStartDying();
		if (!HasControl()) 
			HealthComp.RemoteDie();
		HealthComp.OnDie.Broadcast(Owner);
		bIsDying = true;
		bHasFinishedDying = false;
		DeathAnimDoneTime = 0.0; 
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);

		DeathFeature = SanctuaryWeeperTags::DeathFire;
		if (HealthComp.LastDamageType == EDamageType::MeleeBlunt)
			DeathFeature = SanctuaryWeeperTags::DeathSquish;
		else if (HealthComp.LastDamageType == EDamageType::MeleeSharp)
			DeathFeature = SanctuaryWeeperTags::DeathSpike;

		AnimComp.RequestFeature(DeathFeature, EBasicBehaviourPriority::Maximum, this);

		TriggerStartDyingEffect();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{			
		if (!bHasFinishedDying)		
			TriggerFinishDyingEffect(); // Can occur on remote side

		Owner.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Let animation decide when death is complete
		if ((DeathAnimDoneTime == 0.0) && (ActiveDuration > 0.5))
		{
			TArray<FHazePlayingAnimationData> Animations;
			Mesh.GetCurrentlyPlayingAnimations(Animations);
			for (FHazePlayingAnimationData AnimData : Animations)
			{
				if (AnimData.Sequence == nullptr)
					continue;
				// Assume this is death anim
				DeathAnimDoneTime = Time::GameTimeSeconds + AnimData.Sequence.PlayLength - ActiveDuration;
				break;
			}	
		}
		if (!bHasFinishedDying && (DeathAnimDoneTime > 0.0) && (Time::GameTimeSeconds > DeathAnimDoneTime))
		{
			bHasFinishedDying = true;
			TriggerFinishDyingEffect();
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
		USanctuaryWeeperEffectEventHandler::Trigger_OnRespawn(Owner);
	}

	void TriggerStartDyingEffect()
	{
		if (DeathFeature == SanctuaryWeeperTags::DeathSquish)
			USanctuaryWeeperEffectEventHandler::Trigger_OnStartDyingSquished(Owner);
		else if (DeathFeature == SanctuaryWeeperTags::DeathSpike)
			USanctuaryWeeperEffectEventHandler::Trigger_OnStartDyingSpike(Owner);
		else	
			USanctuaryWeeperEffectEventHandler::Trigger_OnStartDyingFire(Owner);
	}

	void TriggerFinishDyingEffect()
	{
		if (DeathFeature == SanctuaryWeeperTags::DeathSquish)
			USanctuaryWeeperEffectEventHandler::Trigger_OnFinishDyingSquished(Owner);
		else if (DeathFeature == SanctuaryWeeperTags::DeathSpike)
			USanctuaryWeeperEffectEventHandler::Trigger_OnFinishDyingSpike(Owner);
		else	
			USanctuaryWeeperEffectEventHandler::Trigger_OnFinishDyingFire(Owner);
	}
}