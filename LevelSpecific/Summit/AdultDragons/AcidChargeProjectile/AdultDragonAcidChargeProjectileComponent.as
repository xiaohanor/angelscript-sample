event void FOnAcidProjectileReady();

struct FAdultAcidDragonChargeAnimationParams
{
	bool bIsCharging = false;
	bool bShootSuccess = false;
	float ChargeAlpha = 0;
}

UCLASS(Abstract)
class UAdultDragonAcidChargeProjectileComponent : UActorComponent
{
	access Internal = private, UAdultDragonAcidChargeProjectileFireCapability, UAdultDragonAcidChargeProjectileReleaseCapability;

	UPROPERTY()
	FOnAcidProjectileReady OnAcidProjectileReady;

	UPROPERTY()
	UForceFeedbackEffect ChargeForceFeedbackEffect;

	UPROPERTY()
	UForceFeedbackEffect ShotSuccessForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ShotSuccessCameraShake;

	UPROPERTY()
	TSubclassOf<AAdultDragonAcidChargeProjectile> AcidProjectileClass;

	UPROPERTY()
	FAdultAcidDragonChargeAnimationParams ChargeAnimationParams;

	UPROPERTY()
	UHazeCameraSettingsDataAsset ChargeCameraSettings;

	UPROPERTY()
	UHazeCameraSettingsDataAsset FullChargeCameraSettings;

	access:Internal bool bHasSuccessfullyShot = false;
};