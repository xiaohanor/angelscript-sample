class UCoastBomblingSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Damage")
	float DamageFactor = 0.04;

	// How long should death take (including FX and animations)
	UPROPERTY(Category = "Death")
	float DeathDuration = 3.0;

	// This much damage on the player from proximity explosions
	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionPlayerDamage = 1.0;

	// This much damage on enemies from proximity explosions
	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionNpcDamage = 0.5;

	// Proximity explosion radius
	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionRadius = 200.0;

	// Will explode at this distance from the target
	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionDistance = 200.0;

	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionLaunchPushDuration = 0.5;

	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionLaunchFloatDuration = 1.0;

	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionLaunchPointOfInterestDuration = 1.0;

	UPROPERTY(Category = "ProximityExplosion")
	FVector ProximityExplosionLaunchForce = FVector(-750.0*1.5, 800.0*1.5, 400.0*1.5);

	UPROPERTY(Category = "Movement|Wobble")
	float WobbleAmplitude = 25.0;

	UPROPERTY(Category = "Movement|Wobble")
	float WobbleFrequency = 0.25;
	
	UPROPERTY(Category = "Chase")
	float ChaseObstacleAvoidDetectionDistance = 500;
}