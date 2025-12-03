class UCoastWaterskiCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Waterski");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	UCoastWaterskiPlayerComponent WaterskiComp;
	UCoastWaterskiSettings Settings;

	float CurrentGravityAmount;
	bool bGravityApplied = false;

	FHazeAcceleratedFloat AccScale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		WaterskiComp.WaterskiActors.Add(SpawnActor(WaterskiComp.WaterskiActorClass));
		WaterskiComp.WaterskiActors[0].AttachToActor(Player, n"LeftFoot");
		WaterskiComp.WaterskiActors[0].ActorRelativeRotation = FRotator(115.0, 0.0, 0.0);
		WaterskiComp.WaterskiActors[0].ActorRelativeLocation = FVector(16.0, 0.0, -16.0);
		// WaterskiComp.WaterskiActors[0].AddActorDisable(this);
		WaterskiComp.WaterskiActors[0].ActorRelativeScale3D = FVector(KINDA_SMALL_NUMBER, 1, 1);

		WaterskiComp.WaterskiActors.Add(SpawnActor(WaterskiComp.WaterskiActorClass));
		WaterskiComp.WaterskiActors[1].AttachToActor(Player, n"RightFoot");
		WaterskiComp.WaterskiActors[1].ActorRelativeRotation = FRotator(115.0, 0.0, 0.0);
		WaterskiComp.WaterskiActors[1].ActorRelativeLocation = FVector(16.0, 0.0, -16.0);
		// WaterskiComp.WaterskiActors[1].AddActorDisable(this);
		WaterskiComp.WaterskiActors[1].ActorRelativeScale3D = FVector(KINDA_SMALL_NUMBER, 1, 1);

		if(WaterskiComp.DefaultSettings != nullptr)
		{
			Player.ApplyDefaultSettings(WaterskiComp.DefaultSettings);
		}

		Settings = UCoastWaterskiSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WaterskiComp.IsWaterskiing())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WaterskiComp.IsWaterskiing())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(WaterskiComp.CameraSettings != nullptr)
			Player.ApplyCameraSettings(WaterskiComp.CameraSettings, 0.5, this, EHazeCameraPriority::High, 2);

		Player.ApplySettings(WaterskiComp.GravitySettings, this);

		WaterskiComp.WaterskiManager.RequestComp.StartInitialSheetsAndCapabilities(Player, this);
		if(!WaterskiComp.IsWaterskiRopeBlocked())
			WaterskiComp.OnWaterskiRopeEnable();

		FCoastWaterskiGeneralParams Params;
		Params.WaterskiPlayer = Player;
		Params.WaterskiComp = WaterskiComp;
		Params.LeftWaterski = WaterskiComp.WaterskiActors[0];
		Params.RightWaterski = WaterskiComp.WaterskiActors[1];
		UCoastWaterskiEffectHandler::Trigger_OnStartWaterskiing(Player, Params);

		if(Settings.WaterskiGravityForce >= 0.0)
		{
			UMovementGravitySettings::SetGravityAmount(Player, Settings.WaterskiGravityForce, this);
			UMovementGravitySettings::SetTerminalVelocity(Player, -1.0, this);
			CurrentGravityAmount = Settings.WaterskiGravityForce;
			bGravityApplied = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(WaterskiComp.CameraSettings != nullptr)
			Player.ClearCameraSettingsByInstigator(this);

		Player.ClearSettingsByInstigator(this);

		// Waterski manager might be destroyed before this when a progress point is triggered so null check.
		if(WaterskiComp.WaterskiManager != nullptr)
			WaterskiComp.WaterskiManager.RequestComp.StopInitialSheetsAndCapabilities(Player, this);

		FCoastWaterskiGeneralParams Params;
		Params.WaterskiPlayer = Player;
		Params.WaterskiComp = WaterskiComp;
		Params.LeftWaterski = WaterskiComp.WaterskiActors[0];
		Params.RightWaterski = WaterskiComp.WaterskiActors[1];
		UCoastWaterskiEffectHandler::Trigger_OnStopWaterskiing(Player, Params);

		if(bGravityApplied)
		{
			UMovementGravitySettings::ClearGravityAmount(Player, this);
			UMovementGravitySettings::ClearTerminalVelocity(Player, this);
			bGravityApplied = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bGravityApplied && CurrentGravityAmount != Settings.WaterskiGravityForce)
		{
			UMovementGravitySettings::SetGravityAmount(Player, Settings.WaterskiGravityForce, this);
			CurrentGravityAmount = Settings.WaterskiGravityForce;
		}
	}
}