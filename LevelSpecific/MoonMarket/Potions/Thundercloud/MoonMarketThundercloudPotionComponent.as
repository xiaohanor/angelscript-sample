UCLASS(Abstract)
class UMoonMarketThundercloudPotionComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AMoonMarketThunderCloud> CloudClass;
	
	UPROPERTY()
	TSubclassOf<AMoonMarketLightningStrike> LightningClass;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	UForceFeedbackEffect LightningStrikeForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect LightningStrikeForceFeedbackTrigger;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	const float StaticLightningAmount = 7;

	UPROPERTY()
	UCurveFloat StaticChargeCurve;

	UPROPERTY()
	const float ThunderCooldown = 1.5;

	UPROPERTY()
	const float HoverHeight = 400;

};