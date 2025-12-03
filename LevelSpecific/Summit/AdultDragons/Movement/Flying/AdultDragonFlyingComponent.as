class UAdultDragonFlyingComponent : UActorComponent
{
	// Camera settings that are blended in depending on speed
	// 0 -> 1 Flying Min Speed & Flying Max Speed
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset CameraSpeedSettings;

	// Camera settings that are enabled at start of flying and disabled at end of flying
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAdultDragonFlightSettings FlightSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> ImpactShake;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> SpeedShake;

	AHazePlayerCharacter Player;

	bool bIsFlying = false;
	bool bIsStartingFlying = true;

	bool bDriftShouldActivate = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ApplyDefaultSettings(FlightSettings);
	}
};