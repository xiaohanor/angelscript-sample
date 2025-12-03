event void FCoastShoulderTurretLaserHeatLevelChangeEvent(float NewHeatLevel);

class UCoastShoulderTurretLaserOverheatComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FCoastShoulderTurretLaserHeatLevelChangeEvent OnHeatLevelChanged;

	AHazePlayerCharacter Player;
	UCoastShoulderTurretComponent TurretComp;
	UPlayerAimingComponent AimComp;

	ACoastShoulderTurret Turret;
	UCoastShoulderTurretLaserSettings LaserSettings;

	float CurrentHeatLevel;

	float TimeLastShot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		Turret = TurretComp.Turret;

		LaserSettings = UCoastShoulderTurretLaserSettings::GetSettings(Player);

		CurrentHeatLevel = 0.0;
	}

	void SetHeatLevel(float NewHeatLevel)
	{
		CurrentHeatLevel = NewHeatLevel;
		CurrentHeatLevel = Math::Clamp(CurrentHeatLevel, 0, LaserSettings.HeatLevelMax);
		OnHeatLevelChanged.Broadcast(CurrentHeatLevel);
	}
};