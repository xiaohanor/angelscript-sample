class UAdultDragonAirDashComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAdultDragonAirDashSettings Settings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	AHazePlayerCharacter Player;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ApplyDefaultSettings(Settings);
	}
};