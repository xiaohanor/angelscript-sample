struct FSanctuaryBossHydraSmashEnterActivationParams
{
	USanctuaryBossHydraAttackData AttackData;
}

class USanctuaryBossHydraSmashEnterCapability : USanctuaryBossHydraChildCapability
{
	FHazeRuntimeSpline EnterSpline;
	FTransform StartTransform;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossHydraSmashEnterActivationParams& ActivationParams) const
	{
		if (!Head.HasAttackData())
			return false;

		if (Head.AttackData.AttackType != ESanctuaryBossHydraAttackType::Smash)
			return false;

		ActivationParams.AttackData = Head.ConsumeAttackData();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.SmashEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FSanctuaryBossHydraSmashEnterActivationParams& ActivationParams)
	{
		Head.AttackData = ActivationParams.AttackData;
		Head.AnimationData.bIsEnteringSmash = true;
		
		StartTransform = Head.HeadPivot.WorldTransform;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Head.AnimationData.bIsEnteringSmash = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto PointAttack = Cast<USanctuaryBossHydraPointAttackData>(GetAttackData());

		FVector ToHead = (AttackData.WorldLocation - StartTransform.Location);
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

		float TimeRemaining = Math::Max(0.0, Settings.SmashEnterDuration - ActiveDuration);
		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(TargetLocation, TimeRemaining, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(TargetRotation, TimeRemaining, DeltaTime)
		);
	}
}