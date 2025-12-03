class USolarFlareSwingPlatformActivatedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SolarFlareSwingPlatformActivatedCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASolarFlareSwingWeightPlatform Platform;

	float TargetPitch = 90.0;
	float Acceleration = 1.25;
	FRotator TargetRot;

	bool bStopped;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ASolarFlareSwingWeightPlatform>(Owner);
		TargetRot = FRotator(TargetPitch, 0.0, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Platform.bPerching)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Platform.bPerching)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FSolarFlareSwingWeightedPlatformParams Params;
		Params.Location = Platform.ActorLocation;
		Params.bIsMovingUp = true;
		USolarFlareSwingWeightPlatformEffectHandler::Trigger_OnWeightedPlatformStartMoving(Platform, Params);
		bStopped = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Platform.AccelRot.AccelerateTo(TargetRot.Quaternion(), Acceleration, DeltaTime);
		Platform.PlatformRoot.RelativeRotation = Platform.AccelRot.Value.Rotator();

		if (Platform.PlatformRoot.RelativeRotation == TargetRot && !bStopped)
		{
			bStopped = true;
			FSolarFlareSwingWeightedPlatformParams Params;
			Params.Location = Platform.ActorLocation;
			Params.bIsMovingUp = true;
			USolarFlareSwingWeightPlatformEffectHandler::Trigger_OnWeightedPlatformStopMoving(Platform, Params);
		}
	}	
}