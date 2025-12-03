class USolarFlareSwingPlatformReturnCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SolarFlareSwingPlatformReturnCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	ASolarFlareSwingWeightPlatform Platform;

	FRotator TargetRot;

	bool bStopped;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ASolarFlareSwingWeightPlatform>(Owner);
		TargetRot = Platform.PlatformRoot.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Platform.bPerching)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Platform.bPerching)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FSolarFlareSwingWeightedPlatformParams Params;
		Params.Location = Platform.ActorLocation;
		Params.bIsMovingUp = false;
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
		Platform.AccelRot.AccelerateTo(TargetRot.Quaternion(), 4.0, DeltaTime);
		Platform.PlatformRoot.RelativeRotation = Platform.AccelRot.Value.Rotator();
		// Platform.PlatformRoot.RelativeRotation = Math::QInterpConstantTo(Platform.PlatformRoot.RelativeRotation.Quaternion(), TargetRot.Quaternion(), DeltaTime, Acceleration).Rotator();

		if (Platform.PlatformRoot.RelativeRotation == TargetRot && !bStopped)
		{
			bStopped = true;
			FSolarFlareSwingWeightedPlatformParams Params;
			Params.Location = Platform.ActorLocation;
			Params.bIsMovingUp = false;
			USolarFlareSwingWeightPlatformEffectHandler::Trigger_OnWeightedPlatformStopMoving(Platform, Params);
		}
	}	
}