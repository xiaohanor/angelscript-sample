class UCoastShoulderTurretLaserSettings : UHazeComposableSettings
{
	// How far you can shoot
	UPROPERTY()
	float LaserMaxDistance = 5000;

	// Camera shake that plays while shooting
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ShootingCameraShake;

	// Damage on impact per second
	UPROPERTY()
	float DamagePerSecond = 10;

	UPROPERTY()
	float HeatLevelMax = 2.0;

	UPROPERTY()
	float HeatGainedPerSecond = 1.0;

	UPROPERTY()
	float HeatLostPerSecond = 2.0;

	UPROPERTY()
	float HeatPercentageThresholdToFire = 0.0;

	// How long after firing before laser starts cooling down	
	UPROPERTY()
	float DelayBeforeCoolingDownStarts = 0.25;

	UPROPERTY()
	UForceFeedbackEffect ShootingRumble;

	UPROPERTY()
	UForceFeedbackEffect ShootingTriggerRumble;

}