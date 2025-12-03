struct FSanctuaryBossHydraFireBreathEnterActivationParams
{
	USanctuaryBossHydraAttackData AttackData;
}

class USanctuaryBossHydraFireBreathEnterCapability : USanctuaryBossHydraChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossHydraFireBreathEnterActivationParams& ActivationParams) const
	{
		if (!Head.HasAttackData())
			return false;

		if (Head.AttackData.AttackType != ESanctuaryBossHydraAttackType::FireBreath)
			return false;

		ActivationParams.AttackData = Head.ConsumeAttackData();
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.FireBreathEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FSanctuaryBossHydraFireBreathEnterActivationParams& ActivationParams)
	{
		Head.AttackData = ActivationParams.AttackData;
		Head.AnimationData.bIsEnteringFireBreath = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Head.AnimationData.bIsEnteringFireBreath = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = (ActiveDuration / Settings.FireBreathEnterDuration);
		float TimeRemaining = Math::Max(0.0, Settings.FireBreathEnterDuration - ActiveDuration);

		auto SweepAttack = Cast<USanctuaryBossHydraSweepAttackData>(GetAttackData());

		auto HeadSpline = SweepAttack.HeadSpline;
		FVector HeadLocation = HeadSpline.Points[0];

		auto TargetSpline = SweepAttack.TargetSpline;
		FVector TargetLocation = TargetSpline.Points[0];

		if (SweepAttack.TargetComponent != nullptr)
		{
			HeadLocation = SweepAttack.TargetComponent.WorldTransform.TransformPosition(HeadLocation);
			TargetLocation = SweepAttack.TargetComponent.WorldTransform.TransformPosition(TargetLocation);
		}

		FVector TargetDirection = (TargetLocation - HeadLocation).GetSafeNormal();
		FQuat RotationOffset = FRotator(Settings.MouthPitch, 0.0, 0.0).Quaternion();
		FQuat HeadRotation = TargetDirection.ToOrientationQuat() * RotationOffset.Inverse();

		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(HeadLocation, TimeRemaining, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(HeadRotation, TimeRemaining, DeltaTime)
		);
	}
}