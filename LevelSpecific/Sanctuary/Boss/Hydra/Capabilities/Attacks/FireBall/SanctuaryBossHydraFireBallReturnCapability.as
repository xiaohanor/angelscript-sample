class USanctuaryBossHydraFireBallReturnCapability : USanctuaryBossHydraChildCapability
{
	FHazeRuntimeSpline ReturnSpline;
	FTransform StartTransform;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.FireBallReturnDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartTransform = Head.HeadPivot.WorldTransform;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Head.ConsumeAttackData();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform TargetTransform = Head.GetIdleTransform();

		ReturnSpline = FHazeRuntimeSpline();
		ReturnSpline.AddPoint(StartTransform.Location);
		ReturnSpline.AddPoint(TargetTransform.Location);

		float Alpha = (ActiveDuration / Settings.FireBallReturnDuration);
		float TimeRemaining = Math::Max(0.0, Settings.FireBallReturnDuration - ActiveDuration);
		FVector SplineLocation = ReturnSpline.GetLocation(Alpha);

		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(SplineLocation, TimeRemaining, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(TargetTransform.Rotation, TimeRemaining, DeltaTime)
		);
	}
}