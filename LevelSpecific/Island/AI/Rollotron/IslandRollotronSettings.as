class UIslandRollotronSettings : UHazeComposableSettings
{
	// Cost of melee attack in gentleman system
	UPROPERTY(Category = "Gentleman")
	EGentlemanCost ChargeGentlemanCost = EGentlemanCost::Medium;


	// When there are others within this range we will move away from them
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceMaxRange = 300.0;

	// Avoid getting this close to anybody as much as possible
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceMinRange = 80.0;

	// Max acceleration away from others
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceForce = 50.0;
	

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphDuration = 0.75;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphHeight = 300.0;

	UPROPERTY(Category = "Charge")
	float ChargeHitRadius = 80.0;

	UPROPERTY(Category = "Charge")
	float ChargeRange = 1000.0;

	UPROPERTY(Category = "Charge")
	float ChargeDamage = 0.1;

	UPROPERTY(Category = "Charge")
	float ChargeTokenCooldown = 3.0;
	
	UPROPERTY(Category = "Charge")
	float ChargeMaxDuration = 5.0;
	
	UPROPERTY(Category = "Charge")
	FVector ChargeOffset = FVector(0, 0, 100.0);
	
	UPROPERTY(Category = "Charge")
	float ChargeOffsetDistance = 300.0;
	
	UPROPERTY(Category = "Charge")
	float ChargeImpulseAngle = 10.0;

	UPROPERTY(Category = "Charge")
	float ChargeImpulseFactor = 2.0;


	UPROPERTY(Category = "Attack")
	float DetonationRange = 200.0;

	UPROPERTY(Category = "Attack")
	float InstantDetonationRange = 50.0;

	UPROPERTY(Category = "Attack")
	float ExplosionDamageRange = 150.0;

	UPROPERTY(Category = "Attack")
	float ExplosionDamage = 1.0;

	UPROPERTY(Category = "Sidescroller|Attack")
	float SidescrollerExplodeRange = 100.0;

	UPROPERTY(Category = "Sidescroller|Attack")
	float SidescrollerExplosionDamageRange = 225.0;

	UPROPERTY(Category = "Sidescroller|Attack")
	float SidescrollerExplosionDamage = 0.2;


	UPROPERTY(Category = "Chase")
	float ChaseMinRange = 0.0;
	
	UPROPERTY(Category = "Chase")
	float ChaseMaxRange = 7500.0;

	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 400.0;

	UPROPERTY(Category = "Chase")
	float FlyingChaseHeight = 100.0;

	UPROPERTY(Category = "Sidescroller|Chase")
	float SidescrollerChaseMinRange = 0.0;
	
	UPROPERTY(Category = "Sidescroller|Chase")
	float SidescrollerChaseMoveSpeed = 1000.0;
	
	UPROPERTY(Category = "Sidescroller|Chase")
	float SidescrollerFlyingChaseHeight = 100.0;

	// Damage taken per bullet
	UPROPERTY(Category = "Damage")
	float DefaultDamage	= 0.075;

	UPROPERTY(Category = "Damage")
	float HurtReactionDuration = 0.1;
}

