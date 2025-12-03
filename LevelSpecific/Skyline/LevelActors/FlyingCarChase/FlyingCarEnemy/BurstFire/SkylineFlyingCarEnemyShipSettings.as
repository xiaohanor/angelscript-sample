class USkylineFlyingCarEnemyShipSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Burst Fire")
	float MaxAttackRange = 30000.0;
	
	UPROPERTY(Category = "Burst Fire")
	float MinAttackRange = 500.0;
	
	// For how long the weapon telegraph before launching projectiles
	UPROPERTY(Category = "Burst Fire")
	float TelegraphLaunchDuration = 1.0;

	// Damage to player car per projectile
	UPROPERTY(Category = "Burst Fire")
	float BurstProjectileDamage = 0.1;
	
	// Number of projectiles fired in a burst
	UPROPERTY(Category = "Burst Fire")
	int BurstProjectileAmount = 15;

	// Time between each projectile in a burst
	UPROPERTY(Category = "Burst Fire")
	float TimeBetweenBurstProjectiles = 0.05;

	// Time between bursts
	UPROPERTY(Category = "Burst Fire")
	float BurstLaunchInterval = 1.0;

	// Initial impulse speed of projectiles
	UPROPERTY(Category = "Burst Fire")
	float LaunchSpeed = 15000.0;

	// Predict player location with player's velocity times AimAheadTime
	UPROPERTY(Category = "Burst Fire")
	float AimAheadTime = 0.9;
	
	// Time it takes to adjust sight to target
	UPROPERTY(Category = "Burst Fire")
	float AimAheadDuration = 0.2;

	UPROPERTY(Category = "Burst Fire")
	float MaxPitch = 15.0;

	UPROPERTY(Category = "Burst Fire")
	float MinPitch = -55.0;

	//
	// Tracking Laser settings
	//

	// Range of telegraph laser beam
	UPROPERTY(Category = "Burst Fire|Tracking Laser")
	float TrackingLaserRange = 30000.0;

	// For how long the laser tracking telegraph before launching projectiles
	UPROPERTY(Category = "Burst Fire|Tracking Laser")
	float TelegraphLaserTrackingDuration = 1.5;
}
