class USolarFlareGrapplePlatformReturnCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SolarFlareGrapplePlatformActivatedCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	ASolarFlareGrapplePlatform Platform;

	float Acceleration = PI * 0.5;
	FRotator TargetRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ASolarFlareGrapplePlatform>(Owner);
		TargetRot = Platform.RotateRoot.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Platform.bGrappling)
			return false;

		if (Time::GameTimeSeconds < Platform.FallTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Platform.bGrappling)
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
		Platform.RotateRoot.RelativeRotation = Math::QInterpConstantTo(Platform.RotateRoot.RelativeRotation.Quaternion(), TargetRot.Quaternion(), DeltaTime, Acceleration).Rotator();
	}	
}