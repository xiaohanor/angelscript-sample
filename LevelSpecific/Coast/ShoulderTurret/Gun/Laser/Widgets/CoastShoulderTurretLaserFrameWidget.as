class UCoastShoulderTurretLaserFrameWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	ACoastShoulderTurret Turret;

	UPROPERTY(BlueprintReadOnly)
	UCoastShoulderTurretLaserOverheatComponent OverheatComp;

	// UPROPERTY(BindWidget)
	// UProgressBar HeatMeter;

	UPROPERTY(BindWidget)
	UImage Frame;

	UCoastShoulderTurretComponent TurretComp;
	UPlayerAimingComponent AimComp;

	UPROPERTY(BlueprintReadOnly)
	UCoastShoulderTurretLaserSettings LaserSettings;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		Turret = TurretComp.Turret;

		OverheatComp = UCoastShoulderTurretLaserOverheatComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);

		LaserSettings = UCoastShoulderTurretLaserSettings::GetSettings(Player);

		// OverheatComp.OnHeatLevelChanged.AddUFunction(this, n"OnHeatLevelChanged");
		// HeatMeter.Percent = OverheatComp.CurrentHeatLevel / LaserSettings.HeatLevelMax;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		float CrosshairFadeAlpha = AimComp.GetCrosshairFadeAlpha();
		Frame.Opacity = CrosshairFadeAlpha;

		// if(OverheatComp.CurrentHeatLevel == 0)
		// 	HeatMeter.SetRenderOpacity(CrosshairFadeAlpha);
		// else
		// 	HeatMeter.SetRenderOpacity(1.0);
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

	// UFUNCTION()
	// private void OnHeatLevelChanged(float NewHeatLevel)
	// {
	 	// HeatMeter.Percent = NewHeatLevel / LaserSettings.HeatLevelMax;
	// }
}