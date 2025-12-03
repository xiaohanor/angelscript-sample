class UStoneBossWeakpointCoverCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStoneBossWeakpointCover WeakpointCover;
	ADragonRunAcidDragon AcidDragon;
	ADragonRunTailDragon TailDragon;

	float MinFollowDistance = 200.0;

	FHazeAcceleratedRotator AccelRot;

	float CameraTime = 3.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeakpointCover = Cast<AStoneBossWeakpointCover>(Owner);
		AcidDragon = TListedActors<ADragonRunAcidDragon>().GetSingle();
		TailDragon = TListedActors<ADragonRunTailDragon>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WeakpointCover.bCanActivateCamera)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CameraTime <= 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelRot.SnapTo(WeakpointCover.FocusCamera.ActorRotation);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCamera(WeakpointCover.FocusCamera, 2.0, this, EHazeCameraPriority::Cutscene);
			UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(-25, this, 2);
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		}

		WeakpointCover.bCanActivateCamera = false;

		CameraTime = WeakpointCover.FocusCameraDelay;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.DeactivateCameraByInstigator(this, 3.0);
			UCameraSettings::GetSettings(Player).FOV.Clear(this, 1.0);
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector BetweenPoint = (AcidDragon.ActorLocation + TailDragon.ActorLocation) / 2;
		FVector FocusLocation = TailDragon.ActorLocation + TailDragon.ActorForwardVector * 1000.0;
		FVector Direction = FocusLocation - WeakpointCover.FocusCamera.ActorLocation;
		// float Distance = Direction.Size();
		Direction.Normalize();

		AccelRot.AccelerateTo(Direction.Rotation(), 1.0, DeltaTime);
		WeakpointCover.FocusCamera.ActorRotation = AccelRot.Value;

		CameraTime -= DeltaTime;
	}

	// bool OutsideMinRange() const
	// {
	// 	FVector BetweenPoint = (AcidDragon.ActorLocation + TailDragon.ActorLocation) / 2;
	// 	float Distance = (BetweenPoint - Weakpoint.FocusCamera.ActorLocation).Size();
	// 	return Distance < MinFollowDistance;
	// }
};