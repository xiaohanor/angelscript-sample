class UBattlefieldHoverboardGrappleSettings : UHazeComposableSettings
{
	// Also used for the grapple to grind
	UPROPERTY()
	float GrappleEnterDuration = 0.1;

	UPROPERTY()
	float GrappleLaunchEnterDuration = 0.36;

	UPROPERTY()
	float GrappleWallrunEnterDuration = 0.36;

	UPROPERTY()
	float GrappleDuration = 1.05;

	UPROPERTY()
	float GrappleLaunchDuration = 1.55;

	/* Speed added when starting to launch.
	The speed is then lerped towards the launch speed of the point itself.*/
	UPROPERTY()
	float GrappleLaunchAdditionalEnterSpeed = 1200.0;

	// Enter speed of normal grapple
	UPROPERTY()
	float GrappleAdditionalSpeed = 1300.0;

	UPROPERTY()
	float GrappleMinimumSpeed = 6000.0;

	UPROPERTY()
	float GrappleMaximumSpeed = 20000.0;

	UPROPERTY()
	TSubclassOf<AGrappleHook> HookClass;
	UPROPERTY()
	UCurveFloat SpeedCurve;
	UPROPERTY()
	UCurveFloat HeightCurve;
	UPROPERTY()
	UHazeCameraSettingsDataAsset GrappleEnterCamSetting;
	UPROPERTY()
	UHazeCameraSettingsDataAsset GrappleCamSetting;
	UPROPERTY()
	UHazeCameraSettingsDataAsset GrappleLagCamSetting;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> GrappleShake;

	UPROPERTY(Category = "Launch")
	UForceFeedbackEffect LaunchRumble;
}