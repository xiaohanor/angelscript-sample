class UCoastShoulderTurretCannonSettings : UHazeComposableSettings
{
	// Number of bullets per second fired
	UPROPERTY()
	int FireRate = 10;

	// How far you can shoot
	UPROPERTY()
	float ShotMaxDistance = 25000;

	// Camera shake that plays when a shot happens
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ShotCameraShake;

	// Damage per second while firing
	UPROPERTY()
	float DamagePerSecond = 30;

	// The maximum index the alternating guns can go to before it loops 
	UPROPERTY()
	int ShootIndexMax = 0;

	UPROPERTY()
	int MaxAmmoCount = 6;

	// How long it takes to do a full reload compared to reloading until full
	UPROPERTY()
	float FullReloadTimeMultiplier = 0.5;

	// How long it takes before one shot is recovered
	UPROPERTY()
	float ShotReloadTime = 0.5;

	UPROPERTY()
	TSubclassOf<UCoastShoulderTurretCannonShotWidget> ShotWidget;

	UPROPERTY()
	UForceFeedbackEffect ShotRumble;

	UPROPERTY()
	UForceFeedbackEffect ShotTriggerRumble;
}