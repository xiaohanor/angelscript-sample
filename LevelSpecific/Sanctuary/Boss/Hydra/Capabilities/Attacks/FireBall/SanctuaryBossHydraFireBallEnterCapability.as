struct FSanctuaryBossHydraFireBallEnterActivationParams
{
	USanctuaryBossHydraAttackData AttackData;
}

class USanctuaryBossHydraFireBallEnterCapability : USanctuaryBossHydraChildCapability
{
	FTransform StartTransform;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossHydraFireBallEnterActivationParams& ActivationParams) const
	{
		if (!Head.HasAttackData())
			return false;

		if (Head.AttackData.AttackType != ESanctuaryBossHydraAttackType::FireBall)
			return false;

		ActivationParams.AttackData = Head.ConsumeAttackData();
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.FireBallEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FSanctuaryBossHydraFireBallEnterActivationParams& ActivationParams)
	{
		Head.AttackData = ActivationParams.AttackData;
		StartTransform = Head.HeadPivot.WorldTransform;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeRemaining = Math::Max(0.0, Settings.FireBallEnterDuration - ActiveDuration);
		FVector TargetDirection = (AttackData.WorldLocation - Head.HeadPivot.WorldLocation).GetSafeNormal();
		FVector TargetLocation = Head.HeadPivot.WorldLocation - TargetDirection * 250.0;

		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(TargetLocation, TimeRemaining, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(TargetDirection.ToOrientationQuat(), TimeRemaining, DeltaTime)
		);
	}
}