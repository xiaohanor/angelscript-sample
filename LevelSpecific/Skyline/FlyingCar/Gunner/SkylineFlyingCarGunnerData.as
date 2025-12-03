enum EFlyingCarGunnerState
{
	Seating,
	Rifle,
	Bazooka
}

struct FFlyingCarGunnerRifleWidgetData
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCrosshairWidget> CrosshairWidget;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UHazeUserWidget> HitMarkerWidget;
}

struct FFlyingCarGunnerRifleData
{
	UPROPERTY()
	TSubclassOf<AFlyingCarGunnerRifle> RifleClass;

	UPROPERTY()
	UFlyingCarGunnerRifleSettings Settings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ShootingCameraShakeClass;
}

struct FFlyingCarGunnerBazookaData
{
	UPROPERTY()
	TSubclassOf<AFlyingCarGunnerBazooka> BazookaClass;

	UPROPERTY()
	TSubclassOf<ASkylineFlyingCarBazookaRocket> BazookaRocketClass;


	UPROPERTY()
	UFlyingCarGunnerBazookaSettings Settings;


	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ShootCameraShake;

	UPROPERTY()
	UForceFeedbackEffect ShootForceFeedbackEffect;
}

struct FFlyingCarGunnerBazookaWidgetData
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UFlyingCarBazookaCrosshairWidget> CrosshairWidget;
}

event void FFlyingCarGunnerReloadEvent();