class UFerrisWindmillBladeRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AFerrisWindmillBlades Blades;
	float CurrentSpeed;
	float TargetSpeed = 20.0;
	float MoveDuration = 4.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Blades = Cast<AFerrisWindmillBlades>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Blades.bStartRotation)
			return false;

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
		// FQuat CurrentQuat = Blades.WheelRotationPoint.RelativeRotation.Quaternion();
		// Blades.WheelRotationPoint.RelativeRotation = FQuat::Slerp(CurrentQuat, Blades.TargetQuat, DeltaTime).Rotator();

		float Alpha = Blades.MoveCurve.GetFloatValue(ActiveDuration / MoveDuration);
		Alpha = Math::Clamp(Alpha, 0, 1);
		PrintToScreen(f"{Alpha=}");
		PrintToScreen(f"{ActiveDuration=}");
		Blades.ActorLocation = Math::Lerp(Blades.StartingLocation, Blades.TargetLocation, Alpha);
		Blades.ActorRotation = Math::LerpShortestPath(Blades.StartingRotation, Blades.TargetRotation, Alpha);

		CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaTime, TargetSpeed / 4);
		Blades.WheelRotationPoint.AddLocalRotation(FRotator(-CurrentSpeed * DeltaTime, 0, 0));
		Blades.PlatformRoot.WorldLocation = Blades.PlatformFollowPoint.WorldLocation;
		Blades.PlatformRoot2.WorldLocation = Blades.PlatformFollowPoint2.WorldLocation;
	}
};