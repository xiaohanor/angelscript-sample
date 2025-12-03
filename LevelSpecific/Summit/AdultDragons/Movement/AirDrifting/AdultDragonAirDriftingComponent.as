class UAdultDragonAirDriftingComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAdultDragonAirDriftingSettings Settings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	AHazePlayerCharacter Player;

	bool bIsDrifting = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		Player.ApplyDefaultSettings(Settings);
	}
};