class USanctuaryBossHydraIdleCapability : USanctuaryBossHydraChildCapability
{
	default CapabilityTags.Add(n"HydraHeadMovement");

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
		Head.AnimationData.bIsIdling = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Head.AnimationData.bIsIdling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform IdleTransform = Head.GetIdleTransform();

		Head.HeadPivot.SetWorldLocationAndRotation(
			Head.AcceleratedLocation.AccelerateTo(IdleTransform.Location, 2.0, DeltaTime),
			Head.AcceleratedQuat.AccelerateTo(IdleTransform.Rotation, 2.0, DeltaTime)
		);
	}
}