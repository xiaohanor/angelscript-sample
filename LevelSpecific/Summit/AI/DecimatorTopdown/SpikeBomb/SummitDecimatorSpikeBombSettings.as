class USummitDecimatorSpikeBombSettings : UHazeComposableSettings
{
	//
	// Launched On Hit by Roll Params
	//

	// Angle from ground applied to direction of impulse on hit by roll without auto aim assist.
	UPROPERTY(Category = "SpikeBomb")
	float SpikeBombHitByRollFlightAngle = 30;

	// Angle from Roll hit direction to Decimator direction permitted to enable auto aim assist
	UPROPERTY(Category = "SpikeBomb")
	float SpikeBombHitByRollAutoAimAngle = 90;

	// Trajectory arc height when auto aim launching towards the Decimator
	UPROPERTY(Category = "SpikeBomb")
	float SpikeBombHitByRollAutoAimArcHeight = 2000;
	
	// Trajectory arc height when auto aim launching towards the Decimator in phase three
	UPROPERTY(Category = "SpikeBomb")
	float SpikeBombHitByRollAutoAimArcHeightPhaseThree = 500;
	
	// Gravity is multiplied with this factor
	UPROPERTY(Category = "SpikeBomb")
	float SpikeBombGravityScale = 10;


	//
	// General Detonation Params
	//

	// Damage to player
	UPROPERTY(Category = "Detonation")
	float DetonationExplosionPlayerDamage = 0.9;

	// Damage radius of explosion player
	UPROPERTY(Category = "SelfDetonation")
	float DetonationExplosionDamageRange = 500;


	//
	// Self Detonation
	//

	// Countdown time for detonation
	UPROPERTY(Category = "SelfDetonation")
	float SelfDetonationTime = 8.0;

	// Damage to player
	UPROPERTY(Category = "SelfDetonation")
	float SelfDetonationExplosionDamage = 0.3;
	


	//
	// Player Impact Detonation
	//

	// Min range to player for detonation
	UPROPERTY(Category = "PlayerImpactDetonation")
	float PlayerImpactDetonationActivationRange = 300;
	


	//
	// Decimator Impact Detonation
	//

	// Min range to Decimator for detonation
	UPROPERTY(Category = "DecimatorImpactDetonation")
	float DecimatorDetonationRange = 800;
	
	// Damage dealt to Decimator on explosion impact
	UPROPERTY(Category = "DecimatorImpactDetonation")
	float DecimatorDetonationExplosionDamage = 0.05;

	// Min health limit that Decimator can reach by being hit by spikebombs. After this limit, he goes into knocked out state on every hit w/o taking health damage.
	UPROPERTY(Category = "DecimatorImpactDetonation")
	float DecimatorMinHealthLimit = 0.075;

	//
	// Danger Trail
	//

	// How often danger trail is spawned
	UPROPERTY(Category = "DangerTrail")
	float DangerTrailSpawnInterval = 0.25;

	// Max simultaneous trail actors
	UPROPERTY(Category = "DangerTrail")
	float DangerTrailMaxSpawnCount = 40;

	// How long before unspawning.
	UPROPERTY(Category = "DangerTrail")
	float DangerTrailTimeToLive = 8.0;

	// Scale will diminish towards 0 with a speed proportional to this factor.
	UPROPERTY(Category = "DangerTrail")
	float DangerTrailScaleDiminishFactor = 0.25;


	//
	// Explosion Trail
	//

	// How long before unspawning.
	UPROPERTY(Category = "ExplosionTrail")
	float ExplosionTrailTimeToLive = 8.0;

	// Scale will diminish towards 0 with a speed proportional to this factor.
	UPROPERTY(Category = "ExplosionTrail")
	float ExplosionTrailScaleDiminishFactor = 0.25;


};