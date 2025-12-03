class UIslandZoomotronSettings : UHazeComposableSettings
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
	float ChargeTelegraphDuration = 2.0;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphHeight = 300.0;

	UPROPERTY(Category = "Charge")
	float ChargeHitRadius = 80.0;

	UPROPERTY(Category = "Charge")
	float ChargeDamage = 0.5;

	UPROPERTY(Category = "Charge")
	float ChargeTokenCooldown = 3.0;

	
	UPROPERTY(Category = "Attack")
	float ExplodeRange = 150.0;

	UPROPERTY(Category = "Attack")
	float ExplosionDamageRange = 200.0;

	UPROPERTY(Category = "Attack")
	float ExplosionDamage = 0.2;

	UPROPERTY(Category = "Sidescroller|Attack")
	float SidescrollerExplodeRange = 100.0;

	UPROPERTY(Category = "Sidescroller|Attack")
	float SidescrollerExplosionDamageRange = 225.0;

	UPROPERTY(Category = "Sidescroller|Attack")
	float SidescrollerExplosionDamage = 0.9;


	UPROPERTY(Category = "Chase")
	float ChaseMinRange = 500.0;
	
	UPROPERTY(Category = "Chase")
	float ChaseMaxRange = 5000.0;

	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 1000.0;

	UPROPERTY(Category = "Chase")
	float FlyingChaseHeight = 100.0;

	UPROPERTY(Category = "Sidescroller|Chase")
	float SidescrollerChaseMinRange = 0.0;
	
	UPROPERTY(Category = "Sidescroller|Chase")
	float SidescrollerChaseMoveSpeed = 1000.0;
	
	UPROPERTY(Category = "Sidescroller|Chase")
	float SidescrollerFlyingChaseHeight = 100.0;


	UPROPERTY(Category = "Damage")
	float DefaultDamage	= 0.4;

	UPROPERTY(Category = "Damage")
	float HurtReactionDuration = 0.8;
}

