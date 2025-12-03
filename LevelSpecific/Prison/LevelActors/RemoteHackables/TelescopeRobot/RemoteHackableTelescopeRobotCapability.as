class URemoteHackableTelescopeRobotCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 5;

	ARemoteHackableTelescopeRobot TelescopeRobot;
	UPlayerHealthComponent HealthComp;

	float MoveSpeed = 500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		TelescopeRobot = Cast<ARemoteHackableTelescopeRobot>(Owner);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::SecondaryLevelAbility;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;

		Player.ShowTutorialPrompt(TutorialPrompt, this);

		TelescopeRobot.SyncedActorPosition.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.ApplyClampsPitch(-15.0, 89.0);
		UCameraSettings::GetSettings(Player).Clamps.Apply(ClampSettings, this, 1.0, EHazeCameraPriority::High);

		HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.OnStartDying.AddUFunction(this, n"PlayerDied");
	}

	UFUNCTION()
	private void PlayerDied()
	{
		TelescopeRobot.StartRespawning();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);

		Player.ClearCameraSettingsByInstigator(this);

		TelescopeRobot.SyncedActorPosition.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		
		UCameraSettings::GetSettings(Player).Clamps.Clear(this);

		HealthComp.OnStartDying.Unbind(this, n"PlayerDied");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);
	}
}