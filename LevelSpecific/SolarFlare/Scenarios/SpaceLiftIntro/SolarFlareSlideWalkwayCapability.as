class USolarFlareSlideWalkwayCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASolarFlareSlideWalkway Walkway;
	FQuat TargetQuat;
	bool bDeactivate = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Walkway = Cast<ASolarFlareSlideWalkway>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Walkway.bActivated)
			return false;

		if (bDeactivate)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bDeactivate)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetQuat = FRotator(Walkway.DegreesTarget, 0.0, 0.0).Quaternion();

		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayCameraShake(Walkway.CameraShakeStart, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat CurrentQuat = Walkway.MeshRoot.RelativeRotation.Quaternion();
		Walkway.MeshRoot.RelativeRotation = Math::QInterpConstantTo(CurrentQuat, TargetQuat, DeltaTime, PI / 15).Rotator();

		if (Math::Abs(Walkway.MeshRoot.RelativeRotation.Pitch - TargetQuat.Rotator().Pitch) < 0.1)
		{
			bDeactivate = true;
		}
	}
};