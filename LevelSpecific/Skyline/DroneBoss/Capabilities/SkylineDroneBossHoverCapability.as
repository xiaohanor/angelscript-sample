class USkylineDroneBossHoverCapability : USkylineDroneBossChildCapability
{
	default CapabilityTags.Add(SkylineDroneBossTags::SkylineDroneBossHover);

	FHazeAcceleratedVector AcceleratedLocation;

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
		FVector TargetLocation = FVector::UpVector * Math::Sin(Time::GameTimeSeconds * 0.6) * 100.0;

		Boss.BodyPivot.RelativeLocation = AcceleratedLocation.AccelerateTo(
			TargetLocation,
			1.0,
			DeltaTime
		);
	}
}