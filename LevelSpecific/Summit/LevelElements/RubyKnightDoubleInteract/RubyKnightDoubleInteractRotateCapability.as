class URubyKnightDoubleInteractRotateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ARubyKnightDoubleInteract DoubleInteract;

	FHazeAcceleratedRotator AccelRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DoubleInteract = Cast<ARubyKnightDoubleInteract>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DoubleInteract.bComplete)
			return false;

		if (DoubleInteract.bIsReacting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DoubleInteract.bComplete)
			return true;
		
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
		AccelRot.AccelerateTo(DoubleInteract.TargetRotation, DoubleInteract.RotateAccelerationDuration, DeltaTime);
		DoubleInteract.ActorRotation = AccelRot.Value;
	}
};