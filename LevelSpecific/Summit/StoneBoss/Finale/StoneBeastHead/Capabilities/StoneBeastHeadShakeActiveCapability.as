class UStoneBeastHeadShakeActiveCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHead);
	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHeadShake);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	default DebugCategory = StoneBeastHead::DebugCategory;

	FRotator StartingRotation;
	// FVector CurrentRotationOffset;

	AStoneBeastHead StoneBeastHead;
	FStoneBeastHeadActionParams QueueParameters;
	UStoneBeastHeadShakeComponent ShakeComp;

	bool bCameraActive = false;

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
		if (ActiveDuration > QueueParameters.Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// StartingRotation = StoneBeastHead.ActorRotation;

		for (auto Player : Game::Players)
		{
			StoneBeastHead.BlockRespawnCapabilities(Player);
		}

		// StoneBeastHead.ActivateCameraForAction(EStoneBeastHeadRotationActionType::Shake);
		//  StoneBeastHead.BlockCapabilities(StoneBeastHead::Tags::StoneBeastHeadCameraFocusUpdater, this);
		UStoneBeastHeadEffectHandler::Trigger_OnStoneBeastStartShake(StoneBeastHead, FStoneBeastHeadParams(StoneBeastHead));

		// ShakeComp.AccRotationOffset.SnapTo(FRotator::ZeroRotator);
		bCameraActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HasControl())
			ShakeComp.ForceKillThrownPlayers();

		ShakeComp.CurrentRotationOffset = FVector::ZeroVector;

		ShakeComp.ResetThrownPlayers();
		for (auto Player : Game::Players)
			StoneBeastHead.UnblockRespawnCapabilities(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float PitchAmplitude = StoneBeastHead::Shake::PitchAmplitude;
		const float PitchFrequency = StoneBeastHead::Shake::PitchFrequency;
		const float Pitch = ShakeComp.UpdateSineOffset(DeltaTime, PitchFrequency, PitchAmplitude, ShakeComp.CurrentRotationOffset.X);

		const float YawAmplitude = StoneBeastHead::Shake::YawAmplitude;
		const float YawFrequency = StoneBeastHead::Shake::YawFrequency;
		const float Yaw = ShakeComp.UpdateSineOffset(DeltaTime, YawFrequency, YawAmplitude, ShakeComp.CurrentRotationOffset.Y);

		const float RollAmplitude = StoneBeastHead::Shake::RollAmplitude;
		const float RollFrequency = StoneBeastHead::Shake::RollFrequency;
		const float Roll = ShakeComp.UpdateSineOffset(DeltaTime, RollFrequency, RollAmplitude, ShakeComp.CurrentRotationOffset.Z);
		FRotator RotationOffset = FRotator(Pitch, Yaw, Roll);

		float Stiffness = 30;
		float Damping = 0.8;
		float RemainingDuration = QueueParameters.Duration - ActiveDuration;
		if (RemainingDuration <= 1)
		{
			//make camera lag behind a bit more from the end until we have reset
			StoneBeastHead.DefaultFocusCameraActor.LocationDuration = 7;
			StoneBeastHead.DefaultFocusCameraActor.RotationDuration = 7;
			Damping = 0.6;
			Stiffness = 30;
		}
		else if (RemainingDuration <= 2)
			Damping = 0.8;
		else
			Damping = 0.4;

		ShakeComp.AccRotationOffset.SpringTo(RotationOffset, Stiffness, Damping, DeltaTime);

		StoneBeastHead.SetActorRotation(ShakeComp.StartingRotation + ShakeComp.AccRotationOffset.Value);

		if (HasControl())
		{
			if (ActiveDuration > StoneBeastHead::Throw::ActivateTime + Network::PingRoundtripSeconds * 0.5 && ActiveDuration < QueueParameters.Duration - 0.15)
			{
				auto ThrowRotation = StoneBeastHead.ActorTransform.TransformRotation(ShakeComp.AccRotationOffset.Value);
				ShakeComp.ThrowUnpinnedPlayers(ThrowRotation.UpVector, (ThrowRotation.RightVector - ThrowRotation.ForwardVector)*0.5);
			}

			ShakeComp.TryKillThrownPlayers();
		}
	}
};