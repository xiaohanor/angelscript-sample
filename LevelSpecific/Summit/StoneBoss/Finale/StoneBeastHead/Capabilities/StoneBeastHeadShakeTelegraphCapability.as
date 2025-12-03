class UStoneBeastHeadShakeTelegraphCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHead);
	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHeadShakeTelegraph);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = StoneBeastHead::DebugCategory;

	FRotator StartingRotation;
	FVector CurrentRotationOffset;

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
		if (ActiveDuration > QueueParameters.Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShakeComp.AccRotationOffset.SnapTo(FRotator::ZeroRotator);

		ShakeComp.StartingRotation = QueueParameters.StartRotation;
		StoneBeastHead.ActivateCameraForAction(EStoneBeastHeadRotationActionType::ShakeTelegraph);
		UStoneBeastHeadEffectHandler::Trigger_OnStoneBeastTelegraphShake(StoneBeastHead, FStoneBeastHeadParams(StoneBeastHead));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StoneBeastHead.ActivateCameraForAction(EStoneBeastHeadRotationActionType::Shake);
		StoneBeastHead.DeactivateCameraForAction(EStoneBeastHeadRotationActionType::ShakeTelegraph);
		//CurrentRotationOffset = FVector::ZeroVector;
		// StoneBeastHead.FinishCurrentAction();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float PitchAmplitude = StoneBeastHead::ShakeTelegraph::PitchAmplitude;
		const float PitchFrequency = StoneBeastHead::ShakeTelegraph::PitchFrequency;
		const float Pitch = ShakeComp.UpdateSineOffset(DeltaTime, PitchFrequency, PitchAmplitude, ShakeComp.CurrentRotationOffset.X);

		const float YawAmplitude = StoneBeastHead::ShakeTelegraph::YawAmplitude;
		const float YawFrequency = StoneBeastHead::ShakeTelegraph::YawFrequency;
		const float Yaw = ShakeComp.UpdateSineOffset(DeltaTime, YawFrequency, YawAmplitude, ShakeComp.CurrentRotationOffset.Y);

		const float RollAmplitude = StoneBeastHead::ShakeTelegraph::RollAmplitude;
		const float RollFrequency = StoneBeastHead::ShakeTelegraph::RollFrequency;
		const float Roll = ShakeComp.UpdateSineOffset(DeltaTime, RollFrequency, RollAmplitude, ShakeComp.CurrentRotationOffset.Z);

		ShakeComp.AccRotationOffset.AccelerateTo(FRotator(Pitch, Yaw, Roll), 0.2, DeltaTime);
		StoneBeastHead.SetActorRotation(ShakeComp.StartingRotation + ShakeComp.AccRotationOffset.Value);
	}
};