class USanctuaryBossHydraFireBreathTelegraphCapability : USanctuaryBossHydraChildCapability
{
	float TelegraphDuration;
	bool bTriggeredAnimation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > TelegraphDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TelegraphDuration = AttackData.TelegraphDuration;
		if (TelegraphDuration < 0.0)
			TelegraphDuration = Settings.FireBreathTelegraphDuration;

		if (Settings.OpenJawAnimation != nullptr && Settings.bUseAnimSequences)
		{
			FHazePlayFaceAnimationParams FaceParams;
			FaceParams.Animation = Settings.OpenJawAnimation;
			FaceParams.bLoop = true;
			Head.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);
		}

		bTriggeredAnimation = false;
		Head.AnimationData.bIsTelegraphingFireBreath = true;
		USanctuaryBossHydraEventHandler::Trigger_FireBreathTelegraphBegin(Head);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Head.AnimationData.bIsTelegraphingFireBreath = false;
		USanctuaryBossHydraEventHandler::Trigger_FireBreathTelegraphEnd(Head);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Head pivot forward points towards the nose, so in order to get the forward vector
		//  of the mouth we have to rotate downwards
		FVector MouthForwardVector = Head.HeadPivot.ForwardVector.RotateAngleAxis(-Settings.MouthPitch, Head.HeadPivot.RightVector).GetSafeNormal();

		// Trace for VFX
		{
			float BeamLength = Settings.FireBreathBeamLength;
			auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			auto HitResult = Trace.QueryTraceSingle(Head.HeadPivot.WorldLocation, Head.HeadPivot.WorldLocation + MouthForwardVector * BeamLength);

			Head.FireBreathStartLocation = HitResult.TraceStart;
			Head.FireBreathEndLocation = (HitResult.bBlockingHit ? HitResult.ImpactPoint : HitResult.TraceEnd);
		}

		// if (!bTriggeredAnimation && Settings.bUseAnimSequences)
		// {
		// 	if (ActiveDuration > TelegraphDuration - Settings.FireBreathTelegraphAnimationDuration)
		// 	{
		// 		if (Settings.RoarAnimation != nullptr)
		// 		{
		// 			FHazePlayFaceAnimationParams FaceParams;
		// 			FaceParams.Animation = Settings.RoarAnimation;
		// 			Head.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);
		// 		}

		// 		bTriggeredAnimation = true;
		// 	}
		// }
	}
}