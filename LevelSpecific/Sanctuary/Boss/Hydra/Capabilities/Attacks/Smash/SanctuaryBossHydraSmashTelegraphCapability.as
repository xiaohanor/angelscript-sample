class USanctuaryBossHydraSmashTelegraphCapability : USanctuaryBossHydraChildCapability
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

		Head.AnimationData.bIsTelegraphingSmash = true;
		USanctuaryBossHydraEventHandler::Trigger_SmashAttackTelegraphBegin(Head);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Head.AnimationData.bIsTelegraphingSmash = false;
		USanctuaryBossHydraEventHandler::Trigger_SmashAttackTelegraphEnd(Head);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto PointAttack = Cast<USanctuaryBossHydraPointAttackData>(GetAttackData());

		FVector ToHead = (AttackData.WorldLocation - Head.HeadPivot.WorldLocation);
		FVector ToHeadConstrained = ToHead.ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		float OffsetDistance = Head.HeadLength + Settings.SmashEnterDistance;

		FVector UpVector = FVector::UpVector;
		FVector ForwardVector = ToHeadConstrained;
		FVector TargetLocation = AttackData.WorldLocation;
		if (PointAttack.TelegraphComponent != nullptr)
		{
			UpVector = PointAttack.TelegraphComponent.UpVector;
			ForwardVector = PointAttack.TelegraphComponent.ForwardVector;
			TargetLocation = PointAttack.TelegraphComponent.WorldLocation;
		}
		
		FQuat TargetRotation = FQuat::MakeFromZX(UpVector, ForwardVector);
		TargetLocation -= (ForwardVector * OffsetDistance);

		float TimeRemaining = Math::Max(0.0, Settings.SmashTelegraphDuration - ActiveDuration);
		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(TargetLocation, TimeRemaining, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(TargetRotation, TimeRemaining, DeltaTime)
		);

		if (!bTriggeredAnimation && Settings.bUseAnimSequences)
		{
			if (ActiveDuration > TelegraphDuration - Settings.SmashTelegraphAnimationDuration)
			{
				if (Settings.RoarAnimation != nullptr)
				{
					FHazePlayFaceAnimationParams FaceParams;
					FaceParams.Animation = Settings.RoarAnimation;
					Head.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);
				}

				bTriggeredAnimation = true;
			}
		}
	}
}