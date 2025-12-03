class USanctuaryBossHydraSmashReturnCapability : USanctuaryBossHydraChildCapability
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
		if (ActiveDuration > Settings.SmashReturnDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartTransform = Head.HeadPivot.WorldTransform;
		Head.AnimationData.bIsSmashReturning = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Head.ConsumeAttackData();
		Head.AnimationData.bIsSmashReturning = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLocation = Head.HeadTransform.Location;
		FQuat TargetRotation = (AttackData.WorldLocation - Head.HeadTransform.Location).ToOrientationQuat();

		ReturnSpline = FHazeRuntimeSpline();
		ReturnSpline.AddPoint(StartTransform.Location);
		ReturnSpline.AddPoint(TargetLocation);

		float Alpha = (ActiveDuration / Settings.SmashReturnDuration);
		float TimeRemaining = Math::Max(0.0, Settings.SmashReturnDuration - ActiveDuration);
		FVector SplineLocation = ReturnSpline.GetLocation(Alpha);

		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(SplineLocation, TimeRemaining, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(TargetRotation, TimeRemaining, DeltaTime)
		);
	}
}