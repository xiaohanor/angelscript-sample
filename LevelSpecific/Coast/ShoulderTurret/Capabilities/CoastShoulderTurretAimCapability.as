class UCoastShoulderTurretAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShoulderTurret");
	default CapabilityTags.Add(n"Aim");

	default TickGroup = EHazeTickGroup::BeforeMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ACoastShoulderTurret Turret;
	
	UCoastShoulderTurretComponent TurretComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);

		Turret = TurretComp.Turret;
		TurretComp.CrosshairFrameWidget = Player.AddWidget(TurretComp.CrosshairFrameWidgetClass, EHazeWidgetLayer::Crosshair);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Turret.TurretIsActive())
			return false;

		if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Turret.TurretIsActive())
			return true;

		if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(TurretComp.TurretAimCameraSettings, 1.2, this, SubPriority = 150);
		Turret.AimInstigators.Apply(true, this, EInstigatePriority::Normal);
		Turret.OnStartAiming.Broadcast();
		AimComp.StartAiming(Player, TurretComp.TurretAimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
		Turret.AimInstigators.Clear(this);
		Turret.OnStoppedAiming.Broadcast();
		AimComp.StopAiming(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
};