class UAdultDragonTailSmashModeComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAdultDragonTailSmashModeSettings Settings;

	// Camera settings that are enabled at start of SmashMode and disabled at end of SmashMode
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> SmashImpactCameraShake;
	
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> SmashLoopingCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UForceFeedbackEffect SmashRumbleImpact;

	bool bSmashModeActive = false;

	float SmashModeStamina;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ApplyDefaultSettings(Settings);
		SmashModeStamina = Settings.SmashModeStaminaMax;
	}
};