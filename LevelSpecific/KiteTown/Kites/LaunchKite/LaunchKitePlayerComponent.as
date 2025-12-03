class ULaunchKitePlayerComponent : UActorComponent
{
	ULaunchKitePointComponent LaunchKitePointComp;

	UPROPERTY()
	UAnimSequence GrappleAnim;

	UPROPERTY()
	UAnimSequence LaunchAnim;

	UPROPERTY()
	UBlendSpace FlyBS;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY()
	UForceFeedbackEffect LaunchFF;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset FlightCamSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> FlightCamShake;

	bool bLaunched = false;
}