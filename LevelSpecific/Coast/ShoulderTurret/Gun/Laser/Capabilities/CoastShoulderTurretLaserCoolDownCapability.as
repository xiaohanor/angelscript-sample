class UCoastShoulderTurretLaserCoolDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ACoastShoulderTurret Turret;

	UCoastShoulderTurretComponent TurretComp;
	UCoastShoulderTurretLaserOverheatComponent OverheatComp;

	UCoastShoulderTurretLaserSettings LaserSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		OverheatComp = UCoastShoulderTurretLaserOverheatComponent::Get(Player);

		Turret = TurretComp.Turret;

		LaserSettings = UCoastShoulderTurretLaserSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Turret.IsShooting())
			return false;

		if(OverheatComp.CurrentHeatLevel <= 0.0)
			return false;

		if(Time::GetGameTimeSince(OverheatComp.TimeLastShot) < LaserSettings.DelayBeforeCoolingDownStarts)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Turret.IsShooting())
			return true;

		if(OverheatComp.CurrentHeatLevel <= 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float NewHeatLevel = OverheatComp.CurrentHeatLevel;
		NewHeatLevel -= LaserSettings.HeatLostPerSecond * DeltaTime;
		// PrintToScreen(f"{NewHeatLevel}");
		OverheatComp.SetHeatLevel(NewHeatLevel);
	}
};