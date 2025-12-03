class USummitCritterSwarmSettings : UHazeComposableSettings
{
	// Starting number of critters
	UPROPERTY(Category = "Swarm")
	int NumCritters = 50;

	UPROPERTY(Category = "Spawn")
	float SpawningDuration = 5.0;

	UPROPERTY(Category = "Spawn")
	float SpawningSpeed = 10000.0;

	UPROPERTY(Category = "Spawn")
	float SpawningMoveDistance = 5000.0;


	UPROPERTY(Category = "Holding")
	float HoldingSpeed = 2000.0;

	UPROPERTY(Category = "Holding")
	float HoldingRadius = 2000.0;


	UPROPERTY(Category = "Holding")
	float HurtRecoilDuration = 3.0;

	UPROPERTY(Category = "Holding")
	float HurtRecoilSpeed = 10000.0;

	UPROPERTY(Category = "Evade")
	float HurtRecoilRange = 4000.0;

	UPROPERTY(Category = "Holding")
	float HurtRecoilCooldown = 2.0;


	UPROPERTY(Category = "Chase")
	float ChaseSpeed = 4000.0;

	UPROPERTY(Category = "Chase")
	float ChasePassiveRange = 10000.0;

	UPROPERTY(Category = "Chase")
	float ChaseAggroRange = 40000.0;

	UPROPERTY(Category = "Chase")
	FVector ChaseFlankingOffset = FVector(3500.0, 600.0, 100.0);

	UPROPERTY(Category = "Chase")
	float ChaseMinDuration = 5.0;


	UPROPERTY(Category = "GuardSpline")
	float GuardSplineRange = 20000.0;

	UPROPERTY(Category = "GuardSpline")
	float GuardSplineMinRange = 5000.0;

	UPROPERTY(Category = "GuardSpline")
	float GuardSplineMinRangeCooldown = 2.0;

	UPROPERTY(Category = "GuardSpline")
	float GuardSplineMoveSpeed = 4000.0;

	UPROPERTY(Category = "GuardSpline")
	float GuardSplineAtSplineDistance = 2000.0;


	UPROPERTY(Category = "GrabBall")
	float GrabBallRange = 6000.0;

	// Swarm must be in view this many seconds before initiating ball grab
	UPROPERTY(Category = "GrabBall")
	float GrabBallInViewDuration = 0.8;

	// How fast individual critters fly in to grab ball
	UPROPERTY(Category = "GrabBall")
	float GrabBallSpeed = 6000.0;

	// Speed of grabbed ball is reduced by this factor at most (higher value is more hindrance). Fewer grabbers reduce this factor.
	UPROPERTY(Category = "GrabBall")
	float GrabbedBallHindranceFactor = 0.9;

	// When fewer critters than this of the total number of remaining critters are attached to ball we abort grab when taking damage
	UPROPERTY(Category = "GrabBall")
	float GrabBallAbortFraction = 0.5;

	UPROPERTY(Category = "GrabBall")
	float GrabBallAbortCooldown = 3.0;


	UPROPERTY(Category = "Evade")
	float EvadeSpeed = 2000.0;

	UPROPERTY(Category = "Evade")
	float EvadeRange = 8000.0;

	UPROPERTY(Category = "Evade")
	float EvadeMinAngle = 40.0;

	UPROPERTY(Category = "Evade")
	float EvadeMinDuration = 3.0;


	UPROPERTY(Category = "Attack")
	float AttackMaxRange = 12000.0;

	UPROPERTY(Category = "Attack")
	float AttackMinRange = 2000.0;

	UPROPERTY(Category = "Attack")
	float AttackDamage = 0.35;

	UPROPERTY(Category = "Attack")
	float AttackHitRadius = 200;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 2.0;

	UPROPERTY(Category = "Attack")
	float AttackDuration = 2.0;

	// How far ahead of the player we aim. Higher value makes it easier to dodge for the player.
	UPROPERTY(Category = "Attack")
	float AttackPredictFraction = 0.45;

	UPROPERTY(Category = "Attack")
	float AttackCooldown = 5.0;

	UPROPERTY(Category = "Attack")
	float AttackMoveSpeed = 800.0;

	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 1.0;

	UPROPERTY(Category = "Damage")
	float AcidDamage = 0.1;

	UPROPERTY(Category = "Damage")
	float AcidDamageCooldown = 1.0;
	
	UPROPERTY(Category = "Damage")
	float DamagedMinSizeFraction = 0.3;

	UPROPERTY(Category = "Damage")
	float SpawnerDeathDisperseInterval = 0.05;

	UPROPERTY(Category = "AreaConstrain")
	float AreaConstrainAcceleration = 100;

	// UPROPERTY(Category = "Flocking")
	// float FlockingOwnerAccelerationFactor = 10.0;

	UPROPERTY(Category = "Flocking")
	float FlockingOwnerAccelerationFactor = 12000.0;

	UPROPERTY(Category = "Flocking")
	float FlockingRepulseRange = 1500;

	UPROPERTY(Category = "Flocking")
	float FlockingRepulsionFactor = 3000.0;

	UPROPERTY(Category = "Flocking")
	float FlockingAttractionFactor = 10000.0;

	UPROPERTY(Category = "Flocking")
	float FlockingPlayerRepulseRange = 0.0;

	UPROPERTY(Category = "Flocking")
	float FlockingPlayerRepulseFactor = 50.0;

	UPROPERTY(Category = "Flocking")
	float FlockingDamageRepulseRange = 500.0;

	UPROPERTY(Category = "Flocking")
	float FlockingDamageRepulseFactor = 500.0;

	UPROPERTY(Category = "Flocking")
	float FlockingDamageRepulseDuration = 3.0;
}
