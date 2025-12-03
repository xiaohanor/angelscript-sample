class USanctuaryBossHydraSmashAttackCapability : USanctuaryBossHydraChildCapability
{
	FHazeRuntimeSpline AttackSpline;
	FTransform StartTransform;
	bool bTriggeredAnimation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.SmashAttackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bTriggeredAnimation = false;
		StartTransform = Head.HeadPivot.WorldTransform;

		Head.AnimationData.bIsSmashing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto PointAttack = Cast<USanctuaryBossHydraPointAttackData>(GetAttackData());
		if (PointAttack.TargetComponent != nullptr && PointAttack.TargetComponent.Owner != nullptr)
		{
			auto ResponseComponent = USanctuaryBossHydraResponseComponent::Get(PointAttack.TargetComponent.Owner);
			if (ResponseComponent != nullptr)
			{
				ResponseComponent.Smash(Head);
			}
		}

		USanctuaryBossHydraEventHandler::Trigger_SmashAttack(Head);

		if (Settings.IdleAnimation != nullptr && Settings.bUseAnimSequences)
		{
			FHazePlayFaceAnimationParams FaceParams;
			FaceParams.Animation = Settings.IdleAnimation;
			FaceParams.bLoop = true;
			Head.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);
		}

		Head.AnimationData.bIsSmashing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto PointAttack = Cast<USanctuaryBossHydraPointAttackData>(GetAttackData());

		FVector StartLocation = StartTransform.Location;
		FVector AttackDirection = (AttackData.WorldLocation - StartLocation).GetSafeNormal();

		FVector UpVector = FVector::UpVector;
		FVector ForwardVector = AttackDirection;
		if (PointAttack.TelegraphComponent != nullptr)
		{
			UpVector = PointAttack.TelegraphComponent.UpVector;
			ForwardVector = PointAttack.TelegraphComponent.ForwardVector;
		}

		FVector EndLocation = AttackData.WorldLocation - (ForwardVector * Head.HeadLength * 0.7);
		FVector IntermediateLocation = (StartLocation + EndLocation) / 2.0 + (UpVector * 250.0);

		AttackSpline = FHazeRuntimeSpline();
		AttackSpline.AddPoint(StartLocation);
		AttackSpline.AddPoint(IntermediateLocation);
		AttackSpline.AddPoint(EndLocation);

		float Alpha = (ActiveDuration / Settings.SmashAttackDuration);
		Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
		float TimeRemaining = Math::Max(0.0, Settings.SmashAttackDuration - ActiveDuration);

		FVector HeadLocation = AttackSpline.GetLocation(Alpha);
		FQuat HeadRotation = FQuat::MakeFromZX(UpVector, ForwardVector);

		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(HeadLocation, TimeRemaining, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(HeadRotation, TimeRemaining, DeltaTime)
		);

		if (Settings.BiteAnimation != nullptr && Settings.bUseAnimSequences)
		{
			if (!bTriggeredAnimation && ActiveDuration > Settings.SmashAttackDuration - Settings.BiteAnimation.PlayLength)
			{
				FHazePlayFaceAnimationParams FaceParams;
				FaceParams.Animation = Settings.BiteAnimation;
				Head.PlayFaceAnimation(FHazeAnimationDelegate(), FaceParams);

				bTriggeredAnimation = true;
			}
		}
	}
}