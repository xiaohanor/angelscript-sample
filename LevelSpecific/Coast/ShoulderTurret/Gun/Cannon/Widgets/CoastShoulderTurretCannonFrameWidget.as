class UCoastShoulderTurretCannonFrameWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	ACoastShoulderTurret Turret;

	UPROPERTY(BlueprintReadOnly)
	UCoastShoulderTurretCannonAmmoComponent AmmoComp;

	UPROPERTY(BlueprintReadWrite)
	TArray<UCoastShoulderTurretCannonShotWidget> ShotWidgets;

	UPROPERTY(BindWidget)
	UHorizontalBox AmmoHorizontalBox;

	UPROPERTY(BindWidget)
	UImage Frame;

	UCoastShoulderTurretComponent TurretComp;
	UPlayerAimingComponent AimComp;

	UCoastShoulderTurretCannonSettings CannonSettings;

	FHazeAcceleratedFloat AccAmmoOpacity;


	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		AmmoComp = UCoastShoulderTurretCannonAmmoComponent::Get(Player);
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);

		Turret = TurretComp.Turret;

		CannonSettings = UCoastShoulderTurretCannonSettings::GetSettings(Player);

		for(int i = 0; i < CannonSettings.MaxAmmoCount; i++)
		{
			auto ShotWidget = CreateShotWidget();
			ShotWidgets.Add(ShotWidget);
		}

		UpdateAmmoWidgets(AmmoComp.CurrentAmmoCount);
		AmmoComp.OnAmmoChanged.AddUFunction(this, n"UpdateAmmoWidgets");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		float CrosshairFadeAlpha = AimComp.GetCrosshairFadeAlpha();
		Frame.Opacity = CrosshairFadeAlpha;


		float AmmoOpacityTarget;
		if(AmmoComp.CurrentAmmoCount == CannonSettings.MaxAmmoCount)
			AmmoOpacityTarget = CrosshairFadeAlpha;
		else
			AmmoOpacityTarget = 1.0;
		AccAmmoOpacity.AccelerateTo(AmmoOpacityTarget, 0.5, InDeltaTime);
		AmmoHorizontalBox.SetRenderOpacity(AccAmmoOpacity.Value);
	}

	UFUNCTION()
	private void UpdateAmmoWidgets(int NewAmmoCount)
	{
		for(int i = 0; i < ShotWidgets.Num(); i++)
		{
			auto ShotWidget = ShotWidgets[i];
			if(i < NewAmmoCount)
			{
				if(!ShotWidget.bHasAmmo)
					ShotWidget.RecoverAmmo();
			}
			else
			{
				if(ShotWidget.bHasAmmo)
					ShotWidget.SpendAmmo();
			}
		}
	}

	private UCoastShoulderTurretCannonShotWidget CreateShotWidget()
	{
		UCoastShoulderTurretCannonShotWidget NewShotWidget = NewObject(this, CannonSettings.ShotWidget);
		AmmoHorizontalBox.AddChild(NewShotWidget);
		return NewShotWidget;
	}
}