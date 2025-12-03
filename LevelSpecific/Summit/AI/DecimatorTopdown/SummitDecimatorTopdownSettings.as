class USummitDecimatorTopdownSettings : UHazeComposableSettings
{
	//
	// Phase Transitions
	//

	// On this number of hits, the phase will transition to phase 2 from phase 1.
	UPROPERTY(Category = "Phase Transitions")
	int PhaseOneNumSpikeBombHits = 3;

	// On this number of hits, the phase will transition to phase 2 from phase 1.
	UPROPERTY(Category = "Phase Transitions")
	int PhaseTwoNumSpikeBombHits = 6;

	// On this number of hits...
	UPROPERTY(Category = "Phase Transitions")
	int PhaseThreeNumSpikeBombHits = 3;

	//
	// SpikeBomb
	//

	// Impulse added to spikebomb when spawned and launched from the Decimator
	UPROPERTY(Category = "SpikeBomb Spawner")
	float SpikeBombSpawnImpulse1 = 6000.0;
	
	// Impulse added to spikebomb when spawned and launched from the Decimator
	UPROPERTY(Category = "SpikeBomb Spawner")
	float SpikeBombSpawnImpulse2 = 5000.0;

	// Impulse added to spikebomb when spawned and launched from the Decimator
	UPROPERTY(Category = "SpikeBomb Spawner")
	float SpikeBombSpawnImpulse3 = 6000.0;

	// Impulse added to spikebomb when spawned and launched from the Decimator
	UPROPERTY(Category = "SpikeBomb Spawner")
	float SpikeBombSpawnImpulsePhaseThree1 = 8000.0;
	
	// Impulse added to spikebomb when spawned and launched from the Decimator
	UPROPERTY(Category = "SpikeBomb Spawner")
	float SpikeBombSpawnImpulsePhaseThree2 = 5000.0;

	// Impulse added to spikebomb when spawned and launched from the Decimator
	UPROPERTY(Category = "SpikeBomb Spawner")
	float SpikeBombSpawnImpulsePhaseThree3 = 8000.0;


	// Maximum this amount of spawned minions at one time
	UPROPERTY(Category = "SpikeBomb Spawner")
	int SpikeBombMaxSpawnCount = 3;

	// Spawn new minions with this interval in a spawn batch
	UPROPERTY(Category = "SpikeBomb Spawner")
	float SpikeBombSpawnInitialDelay = 1.2;
	
	// Spawn new minions with this interval in a spawn batch
	UPROPERTY(Category = "SpikeBomb Spawner")
	float SpikeBombSpawnInterval = 1.2;


	//
	// Spin Charge Attack
	//
	
	UPROPERTY(Category = "SpinCharge")
	float SpinChargeAcceleration = 2000;

	UPROPERTY(Category = "SpinCharge")
	float SpinChargeMaxSpeed = 4000;

	UPROPERTY(Category = "SpinCharge")
	float SpinChargeBounceFrictionFactor = 0.5;

	UPROPERTY(Category = "SpinCharge")
	float SpinChargeDuration = 12;

	UPROPERTY(Category = "SpinCharge")
	float SpinChargeDamage = 1.0; // One punch!

	UPROPERTY(Category = "SpinCharge")
	bool bSpinChargeEnablePlayerStumble = true; 

	UPROPERTY(Category = "SpinCharge")
	float SpinChargeStumbleDuration = 0.3; 


	// TODO: add settings for acceleration/deceleration


	//
	// Spear Shower
	//

	// Gravity is mulitiplied with this factor.
	UPROPERTY(Category = "SpearShower")
	float SpearGravityScale = 5;

	// Damage per spear
	UPROPERTY(Category = "SpearShower")
	float SpearExplosionDamage = 0.5;

	// Damage range
	UPROPERTY(Category = "SpearShower")
	float SpearExplosionDamageRange = 500;


	//
	// KnockedOut State
	//
	UPROPERTY(Category = "KnockedOut")
	float KnockedOutDuration = 9.0;
	
	UPROPERTY(Category = "KnockedOut")
	float RollHitDamageReactionDuration = 1.47;
	

	UPROPERTY(Category = "KnockedOut")
	float KnockedOutRollHitDamage = 1.0;

	UPROPERTY(Category = "KnockedOut")
	float KnockedOutRecoverDuration = 5.37;
	


	//
	// Spin Arena Platforms
	//
	
	UPROPERTY(Category = "SpinPlatforms")
	float SpinPlatformsDuration = 10;

	UPROPERTY(Category = "SpinPlatforms")
	float SpinPlatformsRotationRate = 30;


	//
	// Spin Decimator and Balcony
	//

	// Turnrate towards center and towards movement direction
	UPROPERTY(Category = "SpinBalcony")
	float DecimatorTurnRate = 120;
			
	UPROPERTY(Category = "SpinBalcony")
	float SpinBalconyRotationRate = 30;


	//
	// Animation Settings
	//

	// Spin Charge Telegraph duration
	UPROPERTY(Category = "Animation | SpinCharge")
	float SpinChargeAnimationTelegraphDuration = 2.4;

	// Turnrate towards camera in knockdown animation
	UPROPERTY(Category = "Animation | Knockdown")
	float TurnInAirTurnRate = 180;


	//
	// Player Trap Settings
	//

	UPROPERTY(Category = "Player Trap")
	float TrapProjectileLandingSteepness = 1000.0;
	
	UPROPERTY(Category = "Player Trap")
	float TrapProjectileAirTime = 1.5;


	//
	// Player Drag settings
	// 

	UPROPERTY(Category = "Drag Ending")
	float MaxPlayerDragSpeed = 750.0;
};