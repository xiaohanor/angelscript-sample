class USpaceLiftPhaseThreeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASolarFlareSpaceLiftMain SpaceLiftMain;
	ASolarFlareSun Sun;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpaceLiftMain = Cast<ASolarFlareSpaceLiftMain>(Owner);
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

		if (!SolarFlareSpaceLiftData::IsStageApplicable(3, SpaceLiftMain.CurrentHits))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SpaceLiftMain.bLiftActive)
			return true;

		if (!SolarFlareSpaceLiftData::IsStageApplicable(3, SpaceLiftMain.CurrentHits))
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.SetStickyRespawnPoint(SpaceLiftMain.RespawnPoint3);

		Sun.SetWaitDuration(3.5);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.AddMovementImpulse(FVector::UpVector * 1800.0);
			SpaceLiftMain.RequestPlayerComp.StartInitialSheetsAndCapabilities(Player, this);
		}

		Timer::SetTimer(this, n"DelayedTeleport", 1.0);

		SpaceLiftMain.TargetRot += FRotator(0.0, 0.0, 90);
		SpaceLiftMain.TargetRotPoleAnchor += FRotator(0.0, 0.0, 0.0);
		
		for (APoleClimbActor Pole : SpaceLiftMain.PoleClimbs)
		{
			Pole.DisablePoleActor();
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCameraCustomBlend(SpaceLiftMain.CameraStage3, SolarFlareSpaceLiftCameraBlend, 3.5, this);
			Player.DeactivateCamera(SpaceLiftMain.CameraStage2);
			Player.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);
		}

		SpaceLiftMain.OnSolarFlareSpaceLiftCubeStageChange.Broadcast(3);
		SpaceLiftMain.Sun.SetWaitDuration(2.0);
		SpaceLiftMain.SpinningCover.ActivateBreakMode();

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.UnlockPlayerMovementFromSpline(this);
			Player.ClearGameplayPerspectiveMode(this);
		}
	}		

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}

	UFUNCTION()
	void DelayedTeleport()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector SmoothToLoc = SpaceLiftMain.LockSplineStage3.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
			Player.SmoothTeleportActor(SmoothToLoc, Player.ActorRotation, this, 0.5);
		}
	}
};