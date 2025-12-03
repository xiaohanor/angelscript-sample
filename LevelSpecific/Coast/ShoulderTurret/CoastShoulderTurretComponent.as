class UCoastShoulderTurretComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	ACoastShoulderTurret Turret;
	
	// Blueprint that gets spawned
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ACoastShoulderTurret> TurretClass;

	// Socket the turret attaches to when spawned
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FName AttachmentSocketName = n"Backpack";

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<UHazeUserWidget> CrosshairFrameWidgetClass;

	// Socket name where you shoot from
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FName MuzzleSocketName = n"Muzzle";

	// Camera settings that get activated when you activate turret
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset TurretCameraSettings;

	// Camera settings that get activated when you start aiming with turret
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset TurretAimCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FAimingSettings TurretAimSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UCoastShoulderTurretCannonSettings CannonSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UCoastShoulderTurretLaserSettings LaserSettings;

	UHazeUserWidget CrosshairFrameWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		Player.ApplyDefaultSettings(CannonSettings);
		Player.ApplyDefaultSettings(LaserSettings);
	}
};