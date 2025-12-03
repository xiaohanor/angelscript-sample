class UStoneBeastHeadRollCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHead);
	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHeadRoll);

	default TickGroup = EHazeTickGroup::Movement;
	default DebugCategory = StoneBeastHead::DebugCategory;

	float CameraLocationDuration;
	float CameraRotationDuration;
	float PreviousRollAmount;

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
	bool ShouldActivate() const
	{
		if (!StoneBeastHead.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= QueueParameters.Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Actor : StoneBeastHead.ActorsToRollWithHead)
		{
			Actor.AttachToActor(StoneBeastHead, NAME_None, EAttachmentRule::KeepWorld);
		}

		for (auto Player : Game::Players)
		{
			StoneBeastHead.BlockRespawnCapabilities(Player);
		}
		PreviousRollAmount = 0;

		UStoneBeastHeadEffectHandler::Trigger_OnStoneBeastStartRoll(StoneBeastHead, FStoneBeastHeadParams(StoneBeastHead));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StoneBeastHead.DeactivateCameraForAction(EStoneBeastHeadRotationActionType::Roll);

		for (auto Actor : StoneBeastHead.ActorsToRollWithHead)
		{
			Actor.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}

		if (HasControl())
		{
			ShakeComp.ForceKillThrownPlayers();
		}

		for (auto Player : Game::Players)
		{
			StoneBeastHead.UnblockRespawnCapabilities(Player);
		}

		ShakeComp.ResetThrownPlayers();
		UStoneBeastHeadEffectHandler::Trigger_OnStoneBeastStopRoll(StoneBeastHead, FStoneBeastHeadParams(StoneBeastHead));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float EasingAlpha = Math::SmoothStep(0, 1, ActiveDuration / QueueParameters.Duration);
		const float TotalRollAmount = EasingAlpha * StoneBeastHead::RollAmount;
		const float RollDelta = TotalRollAmount - PreviousRollAmount;
		const FRotator RotationDelta = FRotator(0, 0, RollDelta);
		StoneBeastHead.AddActorWorldRotation(RotationDelta);
		PreviousRollAmount = TotalRollAmount;

		if (HasControl() && ActiveDuration > Network::PingRoundtripSeconds * 0.5 && ActiveDuration < QueueParameters.Duration - 0.15)
		{
			auto Rotation = StoneBeastHead.ActorTransform.TransformRotation(RotationDelta);
			ShakeComp.ThrowUnpinnedPlayers(Rotation.UpVector, Rotation.RightVector);
			ShakeComp.TryKillThrownPlayers();
		}
	}
};