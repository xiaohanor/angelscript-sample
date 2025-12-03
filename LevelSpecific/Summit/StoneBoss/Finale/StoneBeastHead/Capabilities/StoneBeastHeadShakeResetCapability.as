struct FStoneBeastHeadResetActivateParams
{
	bool bBothPlayersAttachedToFinalPoint = false;
}

class UStoneBeastHeadShakeResetCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHead);

	default TickGroup = EHazeTickGroup::Movement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = StoneBeastHead::DebugCategory;

	FRotator InitialRotation;

	bool bBothPlayersAttachedToFinalPoint = false;

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
	bool ShouldActivate(FStoneBeastHeadResetActivateParams& Params) const
	{
		if (!StoneBeastHead.bIsActive)
			return false;

		Params.bBothPlayersAttachedToFinalPoint = StoneBeastHead.CheckBothPlayersAttachedToFinalPoint();
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
	void OnActivated(FStoneBeastHeadResetActivateParams Params)
	{
		// ShakeComp.State = EStoneBeastHeadShakeState::Reset;
		//AccRotation.SnapTo(StoneBeastHead.ActorRotation);
		bBothPlayersAttachedToFinalPoint = Params.bBothPlayersAttachedToFinalPoint;
		UStoneBeastHeadEffectHandler::Trigger_OnStoneBeastSlowDownShake(StoneBeastHead, FStoneBeastHeadParams(StoneBeastHead));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
			StoneBeastHead.ShakeCameraData.CameraActor.LocationDuration = 0.8;
			StoneBeastHead.ShakeCameraData.CameraActor.RotationDuration = 0.6;

		// ShakeComp.ResetShaking();
		StoneBeastHead.DeactivateCameraForAction(EStoneBeastHeadRotationActionType::Shake);

		if (bBothPlayersAttachedToFinalPoint)
		{
			StoneBeastHead.TryTriggerEnding();
		}

		UStoneBeastHeadEffectHandler::Trigger_OnStoneBeastStopShake(StoneBeastHead, FStoneBeastHeadParams(StoneBeastHead));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//float Alpha = Math::SmoothStep(0, 1, ActiveDuration / QueueParameters.Duration);
		//FRotator NewRotation = FQuat::Slerp(InitialRotation.Quaternion(), StoneBeastHead.StartRotation.Quaternion(), Alpha).Rotator();
		ShakeComp.AccRotationOffset.SpringTo(FRotator::ZeroRotator, 20, 0.6, DeltaTime);
		StoneBeastHead.SetActorRotation(ShakeComp.StartingRotation + ShakeComp.AccRotationOffset.Value);
	}
};