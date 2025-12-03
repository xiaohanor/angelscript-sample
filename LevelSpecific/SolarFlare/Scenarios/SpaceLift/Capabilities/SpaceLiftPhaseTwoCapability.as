class USpaceLiftPhaseTwoCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASolarFlareSpaceLiftMain SpaceLiftMain;
	ASolarFlareSun Sun;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpaceLiftMain = Cast<ASolarFlareSpaceLiftMain>(Owner);

		for (APoleClimbActor Pole : SpaceLiftMain.PoleClimbs)
			Pole.DisablePoleActor();
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

		if (!SolarFlareSpaceLiftData::IsStageApplicable(2, SpaceLiftMain.CurrentHits))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SpaceLiftMain.bLiftActive)
			return true;
		
		if (!SolarFlareSpaceLiftData::IsStageApplicable(2, SpaceLiftMain.CurrentHits))
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Sun.SetWaitDuration(3.5);

		for (AHazePlayerCharacter Player : Game::Players)
			Player.SetStickyRespawnPoint(SpaceLiftMain.RespawnPoint2);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			SpaceLiftMain.RequestPlayerComp.StartInitialSheetsAndCapabilities(Player, this);	
			Player.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);
		}

		Timer::SetTimer(this, n"DelayedTeleport", 2.0);

		for (APoleClimbActor Pole : SpaceLiftMain.PoleClimbs)
		{
			Pole.EnablePoleActor();
		}

		for (ASolarFlareSpaceLiftBreakingCover Cover : SpaceLiftMain.BreakingCovers)
		{
			Cover.ActivateMovement();
			Cover.ActivateBreakingCover();
		}

		SpaceLiftMain.TargetRot += FRotator(0.0, 0.0, 90);
		SpaceLiftMain.TargetRotPoleAnchor += FRotator(0.0, 0.0, 90.0);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCameraCustomBlend(SpaceLiftMain.CameraStage2, SolarFlareSpaceLiftCameraBlend, 3.5, this);
			Player.DeactivateCamera(SpaceLiftMain.CameraStage1);	
		}

		SpaceLiftMain.OnSolarFlareSpaceLiftCubeStageChange.Broadcast(2);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			// Player.UnlockPlayerMovementFromSpline(this);
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
			FVector SmoothToLoc = SpaceLiftMain.LockSplineStage2.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
			Player.SmoothTeleportActor(SmoothToLoc, Player.ActorRotation, this, 0.5);
		}
	}
};