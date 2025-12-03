class UCoastShoulderTurretLaserCrosshairWidget : UCrosshairWidget
{
	UPROPERTY(BlueprintReadOnly)
	ACoastShoulderTurret Turret;

	UPROPERTY(BlueprintReadOnly)
	UCoastShoulderTurretLaserOverheatComponent OverheatComp;

	UCoastShoulderTurretComponent TurretComp;
	UPlayerAimingComponent AimComp;

	UPROPERTY(BlueprintReadOnly)
	UCoastShoulderTurretLaserSettings LaserSettings;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		OverheatComp = UCoastShoulderTurretLaserOverheatComponent::Get(Player);
		Turret = TurretComp.Turret;

		AimComp = UPlayerAimingComponent::Get(Player);

		LaserSettings = UCoastShoulderTurretLaserSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintPure)
	float GetCoolnessLevel()
	{
		float HeatLevel = GetHeatLevel();
		return LaserSettings.HeatLevelMax - HeatLevel;
	}

	UFUNCTION(BlueprintPure)
	float GetHeatLevel()
	{
		return OverheatComp.CurrentHeatLevel / LaserSettings.HeatLevelMax;
	}

	UFUNCTION(BlueprintPure)
	bool IsFullyCooled()
	{
		return OverheatComp.CurrentHeatLevel == 0.0;
	}

	UFUNCTION(BlueprintPure)
	float GetCrosshairOpacity()
	{
		return AimComp.GetCrosshairFadeAlpha();
	}
}