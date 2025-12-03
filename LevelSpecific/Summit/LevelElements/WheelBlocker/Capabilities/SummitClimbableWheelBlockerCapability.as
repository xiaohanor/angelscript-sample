class USummitClimbableWheelBlockerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitClimbableWheelBlocker WheelBlocker;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WheelBlocker = Cast<ASummitClimbableWheelBlocker>(Owner);
	}

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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat CurrentQuat = WheelBlocker.PitchRotateRoot.RelativeRotation.Quaternion();
		WheelBlocker.PitchRotateRoot.RelativeRotation = FQuat::Slerp(CurrentQuat, WheelBlocker.TargetQuat, DeltaTime * 0.75).Rotator();
	}
};