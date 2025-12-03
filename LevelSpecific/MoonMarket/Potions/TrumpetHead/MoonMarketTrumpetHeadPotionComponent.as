class UMoonMarketTrumpetHeadPotionComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AMoonMarketTrumpetHead> TrumpetHeadClass;

	UPROPERTY()
	UForceFeedbackEffect FFToot;

	UPROPERTY()
	UForceFeedbackEffect FFTootTrigger;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	float AirPushRadius = 90;
	
	UPROPERTY()
	float AirPushLength = 250;

	UPROPERTY()
	float AirPushStrength = 200;

	UPROPERTY()
	float HonkCooldown = 0.3;
};