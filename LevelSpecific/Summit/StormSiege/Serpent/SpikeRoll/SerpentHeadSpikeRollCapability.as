class USerpentHeadSpikeRollCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	ASerpentHead Serpent;
	USerpentSpikeRollComponent RollComp;

	float TargetFireDuration = 0.5;
	
	float Duration;
	float FireTime;

	int FireIndex;

	bool bOnActivatedDestroyOnImpact;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Serpent = Cast<ASerpentHead>(Owner);
		RollComp = USerpentSpikeRollComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Serpent.bRunSpikeRollAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Serpent.bRunSpikeRollAttack)
			return true;

		if (ActiveDuration > RollComp.SpinDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FireIndex = 0;
		if (Serpent.SpikeTargets.Num() > 0)
			Duration = TargetFireDuration / Serpent.SpikeTargets.Num();
		else
			Duration = TargetFireDuration;
			
		FireTime = Duration;
		//Serpent.SkeletalMeshBeast.PlaySlotAnimation(RollComp.RollSequenceParams);
		Serpent.SerpentAttackMovementState = ESerpentAttackMovementState::SpikeRoll;
		bOnActivatedDestroyOnImpact = Serpent.bSpikeSeedDestroyOnImpact;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//Serpent.PlayFlyingAnimation();
		Serpent.SerpentAttackMovementState = ESerpentAttackMovementState::FlyForward;
		Serpent.bRunSpikeRollAttack = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (FireIndex > Serpent.SpikeTargets.Num() - 1)
			return;

		FireTime -= DeltaTime;

		while (FireTime <= 0.0)
		{
			FireTime += Duration;
			auto SpikeSeed = SpawnActor(Serpent.SpikeSeedClass, Serpent.ActorLocation);
			SpikeSeed.StartMovingTowardsSpike(Serpent.SpikeTargets[FireIndex]);			
			SpikeSeed.bDestroyOnImpacts = bOnActivatedDestroyOnImpact;
			// FinishSpawningActor(SpikeSeed);
			FireIndex++;
		}
	}
};