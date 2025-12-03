class ATundra_IcePalace_Outer_InsideLockLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	ARespawnPoint InsideLockStartingLocation;
	UPROPERTY()
	FPostProcessSettings DepthOfFieldSettings;
	UPROPERTY()
	AHazeCameraActor InsideLockCamera;
	UPROPERTY()
	ASplineActor SplineActor01;
	UPROPERTY()
	UTundraPlayerFairySettings FairySettings;
	UPROPERTY()
	UPlayerFloorMotionSettings FloorMotionSettings;
	UPROPERTY()
	UPlayerFairyGroundDashSettings FairyGroundDashSettings;
	UPROPERTY()
	UPlayerAirMotionSettings AirMotionSettings;

	bool bPostProcessEnabled = false;

	UFUNCTION()
	void StartInsideLock(AHazePlayerCharacter Player)
	{
		Player.TeleportToRespawnPoint(InsideLockStartingLocation, this);
		Player.ActivateCamera(InsideLockCamera, 0, this, EHazeCameraPriority::High);
		Player.LockPlayerMovementToSpline(SplineActor01, this);
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Small, false);
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		Player.BlockCapabilities(n"Dash", this);
		Player.BlockCapabilities(n"Jump", this);
		EnableDepthPostProcess(true);
		Player.ApplySettings(FairySettings, this, EHazeSettingsPriority::Override);
		Player.ApplySettings(FloorMotionSettings, this, EHazeSettingsPriority::Override);
		Player.ApplySettings(FairyGroundDashSettings, this, EHazeSettingsPriority::Override);
		Player.ApplySettings(AirMotionSettings, this, EHazeSettingsPriority::Override);

		for (AHazePlayerCharacter _Player : Game::GetPlayers())
		{
			_Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
			_Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		}
	}

	UFUNCTION()
	void StopInsideLock(AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(InsideLockCamera, 0);
		Player.UnlockPlayerMovementFromSpline(this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		Player.UnblockCapabilities(n"Dash", this);
		Player.UnblockCapabilities(n"Jump", this);
		EnableDepthPostProcess(false);
		Player.ClearSettingsByInstigator(this);

		for (AHazePlayerCharacter _Player : Game::GetPlayers())
		{
			_Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
			_Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		}
	}

	void EnableDepthPostProcess(bool bEnable)
	{
		if(bEnable)
		{
			bPostProcessEnabled = true;
			Game::Zoe.AddCustomPostProcessSettings(DepthOfFieldSettings, 1, this);
		}
		else
		{
			bPostProcessEnabled = false;
			Game::Zoe.RemoveCustomPostProcessSettings(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bPostProcessEnabled)
			return;

		float Dist = Game::Zoe.GetViewLocation().Distance(Game::Zoe.ActorLocation);
		DepthOfFieldSettings.DepthOfFieldFocalDistance = Dist;
		Game::Zoe.AddCustomPostProcessSettings(DepthOfFieldSettings, 1, this);
	}
};