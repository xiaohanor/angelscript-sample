class USolarFlareGrapplePlatformActivatedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SolarFlareGrapplePlatformActivatedCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASolarFlareGrapplePlatform Platform;

	float TargetPitch = 90.0;
	float Acceleration = PI * 1.0;
	FRotator TargetRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ASolarFlareGrapplePlatform>(Owner);
		TargetRot = FRotator(TargetPitch, 0.0, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Platform.bGrappling)
			return false;

		if (!Platform.PlatformCanMove())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WithinRotationRange())
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
		Platform.bGrappling = false;
		Platform.FallTime = Time::GameTimeSeconds + Platform.FallWaitDuration;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Platform.RotateRoot.RelativeRotation = Math::QInterpConstantTo(Platform.RotateRoot.RelativeRotation.Quaternion(), TargetRot.Quaternion(), DeltaTime, Acceleration).Rotator();
	}	

	bool WithinRotationRange() const
	{
		return TargetRot.Pitch - Platform.RotateRoot.RelativeRotation.Pitch < 0.5;
	}
}