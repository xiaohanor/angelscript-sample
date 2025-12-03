class UStoneBeastHeadRollTelegraphCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHead);
	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHeadRoll);

	default TickGroup = EHazeTickGroup::Movement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = StoneBeastHead::DebugCategory;

	FRotator StartingRotation;

	float PreviousRollAmount;

	AStoneBeastHead StoneBeastHead;
	FStoneBeastHeadActionParams QueueParameters;

	FHazeAcceleratedRotator AccRotationOffset;
	FVector CurrentRotationOffset;
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
		StartingRotation = QueueParameters.StartRotation;
		PreviousRollAmount = 0;
		StoneBeastHead.ActivateCameraForAction(EStoneBeastHeadRotationActionType::RollTelegraph);

		AccRotationOffset.SnapTo(FRotator::ZeroRotator);
		CurrentRotationOffset = FVector::ZeroVector;

		ShakeComp = UStoneBeastHeadShakeComponent::Get(Owner);

		UStoneBeastHeadEffectHandler::Trigger_OnStoneBeastTelegraphRoll(StoneBeastHead, FStoneBeastHeadParams(StoneBeastHead));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StoneBeastHead.ActivateCameraForAction(EStoneBeastHeadRotationActionType::Roll);
		StoneBeastHead.DeactivateCameraForAction(EStoneBeastHeadRotationActionType::RollTelegraph);

		for (auto Actor : StoneBeastHead.ActorsToRollWithHead)
		{
			Actor.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ShakeDuration = 1.6;
		float RollDuration = QueueParameters.Duration - ShakeDuration;
		if (ActiveDuration < ShakeDuration)
		{
			// SHAKE
			const float PitchAmplitude = StoneBeastHead::ShakeTelegraph::PitchAmplitude;
			const float PitchFrequency = StoneBeastHead::ShakeTelegraph::PitchFrequency;
			const float Pitch = ShakeComp.UpdateSineOffset(DeltaTime, PitchFrequency, PitchAmplitude, CurrentRotationOffset.X);

			const float YawAmplitude = StoneBeastHead::ShakeTelegraph::YawAmplitude;
			const float YawFrequency = StoneBeastHead::ShakeTelegraph::YawFrequency;
			const float Yaw = ShakeComp.UpdateSineOffset(DeltaTime, YawFrequency, YawAmplitude, CurrentRotationOffset.Y);

			const float RollAmplitude = StoneBeastHead::ShakeTelegraph::RollAmplitude;
			const float RollFrequency = StoneBeastHead::ShakeTelegraph::RollFrequency;
			const float Roll = ShakeComp.UpdateSineOffset(DeltaTime, RollFrequency, RollAmplitude, CurrentRotationOffset.Z);
			AccRotationOffset.AccelerateTo(FRotator(Pitch, Yaw, Roll), 0.2, DeltaTime);
			StoneBeastHead.SetActorRotation(StartingRotation + AccRotationOffset.Value);
		}
		else
		{
			// Remaining duration == 0.5;
			// ROLL
			float RollActiveDuration = ActiveDuration - ShakeDuration;
			float EasingAlpha = Math::SinusoidalIn(0, 1, RollActiveDuration / RollDuration);
			const float TotalRollAmount = EasingAlpha * StoneBeastHead::TelegraphRollAmount;
			const float RollDelta = TotalRollAmount - PreviousRollAmount;
			const FRotator RotationDelta = FRotator(0, 0, RollDelta);
			StoneBeastHead.AddActorWorldRotation(RotationDelta);
			PreviousRollAmount = TotalRollAmount;
		}
	}
};