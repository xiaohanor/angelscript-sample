struct FHackableSniperTurretActivateParams
{
	AHazePlayerCharacter HijackingPlayer;
}

/**
 * Handles movement and camera controls of the sniper turret
 */
class UHackableSniperTurretCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneHijackCapability);
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AHackableSniperTurret SniperTurret;
	AHazePlayerCharacter Player;
	UOtherPlayerIndicatorComponent OtherPlayerIndicatorComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SniperTurret = Cast<AHackableSniperTurret>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHackableSniperTurretActivateParams& Params) const
	{
		if (!SniperTurret.HijackTargetableComp.IsHijacked())
			return false;

		Params.HijackingPlayer = SniperTurret.HijackTargetableComp.GetHijackPlayer();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SniperTurret.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHackableSniperTurretActivateParams Params)
	{
		Player = Params.HijackingPlayer;

		CapabilityInput::LinkActorToPlayerInput(SniperTurret, Player);
		SniperTurret.AimingComp = UPlayerAimingComponent::Get(Player);

		Player.ApplySettings(SniperTurret.CrosshairSettings, this);
		SniperTurret.AimingComp.StartAiming(SniperTurret, SniperTurret.AimSettings);
		UHackableSniperTurretCrosshairWidget Crosshair = Cast<UHackableSniperTurretCrosshairWidget>(SniperTurret.AimingComp.GetCrosshairWidget(SniperTurret));
		if(Crosshair != nullptr)
		{
			Crosshair.SniperTurret = SniperTurret;
		}

		Player.ActivateCamera(SniperTurret.CameraComp, 2.0, this, EHazeCameraPriority::High);

		UHackableSniperTurretEventHandler::Trigger_OnActivated(SniperTurret);

		OtherPlayerIndicatorComp = UOtherPlayerIndicatorComponent::Get(Player);
		OtherPlayerIndicatorComp.IndicatorMode.Apply(EOtherPlayerIndicatorMode::AlwaysVisible, this);

		UCameraSettings::GetSettings(Player).FOV.Apply(SniperTurret.AimFOV, this, SniperTurret.FOV_BLENDTIME, EHazeCameraPriority::Low);

		SniperTurret.ZoomAlpha.SnapTo(0);

		Player.AddCustomPostProcessSettings(SniperTurret.PostProcessSettings,5,this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CapabilityInput::LinkActorToPlayerInput(SniperTurret, nullptr);

		Player.ClearSettingsByInstigator(this);
		SniperTurret.AimingComp.StopAiming(SniperTurret);

		Player.DeactivateCamera(SniperTurret.CameraComp);

		Player.ClearCameraSettingsByInstigator(this);

		UHackableSniperTurretEventHandler::Trigger_OnDeactivated(SniperTurret);

		OtherPlayerIndicatorComp.IndicatorMode.Clear(this);

		UCameraSettings::GetSettings(Player).FOV.Clear(this, 1);

		SniperTurret.ZoomAlpha.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SniperTurret.HackedDuration = ActiveDuration;
	}

	FAimingRay GetAimingRay() const
	{
		FAimingRay Ray;
		Ray.AimingMode = EAimingMode::Free3DAim;
		Ray.Origin = SniperTurret.MuzzleComp.WorldLocation;
		Ray.Direction = SniperTurret.MuzzleComp.WorldRotation.ForwardVector;
		return Ray;
	}
};