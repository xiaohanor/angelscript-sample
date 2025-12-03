class USkylineExploderSettings : UHazeComposableSettings
{
	// How long should death take (including FX and animations)
	UPROPERTY(Category = "Death")
	float DeathDuration = 3.0;

	// This much damage on the player from proximity explosions
	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionPlayerDamage = 0.2;

	// This much damage on enemies from proximity explosions
	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionNpcDamage = 0.5;

	// Proximity explosion radius
	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionRadius = 150.0;

	// Will explode at this distance from the target
	UPROPERTY(Category = "ProximityExplosion")
	float ProximityExplosionDistance = 100.0;
}
