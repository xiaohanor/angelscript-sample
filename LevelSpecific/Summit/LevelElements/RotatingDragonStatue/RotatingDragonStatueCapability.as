class URotatingDragonStatueCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ARotatingDragonStatue Statue;
	float CurrentBaseRotationOffset;
	float CurrentWingRotationOffset;
	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Statue = Cast<ARotatingDragonStatue>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Statue.bRotationActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Statue.bRotationActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentBaseRotationOffset = 0.0;
		CurrentWingRotationOffset = 0.0;
		StartRotation = Statue.ActorRotation;
		// RotationsPerSecond = Statue.RotationAmount / Statue.Duration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentBaseRotationOffset = Statue.RotationCurve.GetFloatValue(ActiveDuration / Statue.Duration) * Statue.StatueRotationAmount;
		CurrentWingRotationOffset = Statue.WingCurve.GetFloatValue(ActiveDuration / Statue.Duration) * Statue.WingRotationAmount;

		Statue.ActorRotation = StartRotation + FRotator(0, CurrentBaseRotationOffset, 0);
		Statue.LeftWingRoot.RelativeRotation = FRotator(0, 0, CurrentWingRotationOffset);
		Statue.RightWingRoot.RelativeRotation = FRotator(0, -0, -CurrentWingRotationOffset);

		if (CurrentBaseRotationOffset == Statue.StatueRotationAmount)
			Statue.bRotationActive = false;
	}
};