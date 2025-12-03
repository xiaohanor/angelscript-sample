class USpaceLiftPhaseFourCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASolarFlareSpaceLiftMain SpaceLiftMain;
	ASolarFlareSun Sun;
	FQuat TargetQuat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpaceLiftMain = Cast<ASolarFlareSpaceLiftMain>(Owner);
		TargetQuat = (SpaceLiftMain.FirstLaunchPointRoot.RelativeRotation + FRotator(-90.0, 0.0, 0.0)).Quaternion();
		
		for (AGrappleLaunchPoint Launch : SpaceLiftMain.LaunchPoints1)
			Launch.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Sun == nullptr)
			Sun = TListedActors<ASolarFlareSun>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SpaceLiftMain.bLiftActive)
			return false;

		if (!SolarFlareSpaceLiftData::IsStageApplicable(4, SpaceLiftMain.CurrentHits))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SpaceLiftMain.bLiftActive)
			return true;
		
		if (!SolarFlareSpaceLiftData::IsStageApplicable(4, SpaceLiftMain.CurrentHits))
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.SetStickyRespawnPoint(SpaceLiftMain.RespawnPoint4);

		SpaceLiftMain.TargetSplitOffsetY = 600.0;
		Sun.SetWaitDuration(4.0);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			SpaceLiftMain.RequestPlayerComp.StartInitialSheetsAndCapabilities(Player, this);
			// UPlayerMovementComponent::Get(Player).FollowComponentMovement(SpaceLiftMain.Root, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Low);
			FVector SmoothToLoc = SpaceLiftMain.LockSplineStage3.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
			Player.SmoothTeleportActor(SmoothToLoc, Player.ActorRotation, this, 0.5);
			
			Player.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);
		}

		for (AGrappleLaunchPoint Launch : SpaceLiftMain.LaunchPoints1)
			Launch.RemoveActorDisable(this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCameraCustomBlend(SpaceLiftMain.TrackerCam, SolarFlareSpaceLiftCameraBlend, 3.5, this);
			Player.DeactivateCamera(SpaceLiftMain.CameraStage3);
		}

		Sun.SetWaitDuration(1.0);
		SpaceLiftMain.OnSolarFlareSpaceLiftCubeStageChange.Broadcast(4);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.ClearGameplayPerspectiveMode(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat CurrentQuat = SpaceLiftMain.FirstLaunchPointRoot.RelativeRotation.Quaternion();
		SpaceLiftMain.FirstLaunchPointRoot.RelativeRotation = Math::QInterpConstantTo(CurrentQuat, TargetQuat, DeltaTime, PI).Rotator();
	}
};