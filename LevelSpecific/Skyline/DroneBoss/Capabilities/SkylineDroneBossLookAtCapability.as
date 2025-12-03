class USkylineDroneBossLookAtCapability : USkylineDroneBossChildCapability
{
	default CapabilityTags.Add(SkylineDroneBossTags::SkylineDroneBossLookAt);

	FHazeAcceleratedQuat AcceleratedQuat;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedQuat.SnapTo(Boss.BodyPivot.ComponentQuat);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto TargetPlayer = Boss.TargetPlayer.Get();
		FQuat TargetRotation = Boss.BodyPivot.ComponentQuat;
		
		if (TargetPlayer != nullptr)
		{
			FVector ToTargetPlayer = (TargetPlayer.ActorCenterLocation - Boss.BodyPivot.WorldLocation).GetSafeNormal();
			TargetRotation = FQuat::MakeFromXZ(ToTargetPlayer, FVector::UpVector);
		}

		Boss.BodyPivot.WorldRotation = AcceleratedQuat.AccelerateTo(
			TargetRotation,
			2.0,
			DeltaTime
		).Rotator();
	}
}