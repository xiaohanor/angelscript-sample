enum ESummitStoneBeastCritterFlingDeath
{
	AlwaysFling,
	SometimesFling,
	NeverFling
}

class USummitStoneBeastCritterSettings : UHazeComposableSettings
{
	// Cost of attack in gentleman system
	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::XXSmall;

	UPROPERTY(Category = "Attack")
	float AttackRange = 220.0;
	
	// The minimum telegraph duration when attacker is joining an already started knockdown attack.
	UPROPERTY(Category = "Attack")
	float MinAdjustedKnockdownTelegraphDuration = 1.0;
	
	UPROPERTY(Category = "Attack")
	float AttackAbortRange = 400.0;
	
	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 0.25;

	UPROPERTY(Category = "Attack")
	float AttackGroundSpikesDuration = 2.0;

	UPROPERTY(Category = "Entrance")
	bool bUseCrawlSplineEntrance = false;
	
	// We move this fast when crawling along the ground spline
	UPROPERTY(Category = "Entrance")
	float CrawlSplineEntranceSpeed = 200.0;

	// Max range at which we use encircling
	UPROPERTY(Category = "CrowdEncircle")
	float CrowdEncircleMaxRange = 700.0;

	// We want to be at this range from the target at our encircling location
	UPROPERTY(Category = "CrowdEncircle")
	float CrowdEncircleRange = 175.0;
	
	// We add between 0 and this much variability to the desired crowd encircling range
	UPROPERTY(Category = "CrowdEncircle")
	float CrowdEncircleRangeVariable = 50.0;

	// We move this fast when going to our encircling location
	UPROPERTY(Category = "CrowdEncircle")
	float CrowdEncircleSpeed = 200.0;

	// We start moving towards our location when going outside this range of it
	UPROPERTY(Category = "CrowdEncircle")
	float CrowdEncircleActivationRange = 100.0;

	// We stop towards our encircle location when within this range of it
	UPROPERTY(Category = "CrowdEncircle")
	float CrowdEncircleDeactivationRange = 50.0;

	// If off, critters will insta-die
	UPROPERTY(Category = "FlingDeath")
	ESummitStoneBeastCritterFlingDeath FlingDeathRate = ESummitStoneBeastCritterFlingDeath::AlwaysFling;

	// Balance this with FlingDeathGravity
	UPROPERTY(Category = "FlingDeath")
	float FlingDeathImpactForce = 1000;

	// Balance this with FlingDeathImpactForce
	UPROPERTY(Category = "FlingDeath")
	float FlingDeathGravity = 2;

	// Rotation speed while being flung
	UPROPERTY(Category = "FlingDeath")
	float FlingDeathRotationSpeed = 2;
}