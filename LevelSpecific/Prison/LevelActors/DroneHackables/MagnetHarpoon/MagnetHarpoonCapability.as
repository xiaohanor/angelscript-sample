class UMagnetHarpoonCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 5;

	AMagnetHarpoon MagnetHarpoon;
	AHazePlayerCharacter Player;

	UPlayerAimingComponent AimingComp;
	bool bZoomed = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagnetHarpoon = Cast<AMagnetHarpoon>(Owner);
		Player = Drone::GetSwarmDronePlayer();
		AimingComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MagnetHarpoon.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MagnetHarpoon.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MagnetHarpoon.bHasLetGoOfPrimary = false;

		CapabilityInput::LinkActorToPlayerInput(MagnetHarpoon, Player);

		bZoomed = false;

		Player.ApplySettings(MagnetHarpoon.CrosshairSettings, this);
		
		Player.ActivateCamera(MagnetHarpoon.CameraComp, 1.0, this, EHazeCameraPriority::High);
		
		AimingComp.StartAiming(MagnetHarpoon, MagnetHarpoon.AimSettings);

		auto HarpoonCrossHair = Cast<UMagnetHarpoonCrosshair>(AimingComp.GetCrosshairWidget(MagnetHarpoon));
		if(HarpoonCrossHair != nullptr)
		{
			HarpoonCrossHair.Initialize(MagnetHarpoon);
		}

		UMagnetHarpoonEventHandler::Trigger_OnStartHack(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CapabilityInput::LinkActorToPlayerInput(nullptr, Player);

		if(MagnetHarpoon.State == EMagnetHarpoonState::Launched)
			MagnetHarpoon.State = EMagnetHarpoonState::Retracting;

		Player.ClearSettingsByInstigator(this);
	
		Player.DeactivateCamera(MagnetHarpoon.CameraComp);

		Player.ClearCameraSettingsByInstigator(this);

		AimingComp.StopAiming(MagnetHarpoon);

		UMagnetHarpoonEventHandler::Trigger_OnStopHack(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MagnetHarpoon.bHasLetGoOfPrimary && !IsActioning(ActionNames::PrimaryLevelAbility))
			MagnetHarpoon.bHasLetGoOfPrimary = true;
	}

	// void ZoomIn()
	// {
	// 	if (bZoomed)
	// 		return;

	// 	bZoomed = true;
	// 	UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(MagnetHarpoon.ZoomFOVOffset, 0.5, this);
	// }

	// void ZoomOut()
	// {
	// 	if (!bZoomed)
	// 		return;

	// 	bZoomed = false;
	// 	UCameraSettings::GetSettings(Player).FOV.Clear(this, 0.5);
	// }
}