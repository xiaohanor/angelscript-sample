class UStoneBeastHeadWaitCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AStoneBeastHead StoneBeastHead;
	FStoneBeastHeadActionParams QueueParameters;
	UStoneBeastHeadShakeComponent ShakeComp;

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FStoneBeastHeadActionParams Parameters)
	{
		QueueParameters = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBeastHead = Cast<AStoneBeastHead>(Owner);
		ShakeComp = UStoneBeastHeadShakeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > QueueParameters.Duration)
			return true;

		if (!StoneBeastHead.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StoneBeastHead.TryTriggerEnding();
		// float Sin = Math::Sin(ActiveDuration * 2 * PI) * 5;
		// FRotator Bob = StoneBeastHead.ActorRotation + FRotator(Sin, 0, 0) * DeltaTime;
		// StoneBeastHead.SetActorRotation(Bob);
	}
};