

class UIslandFloatotronSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Attack")
	float AttackMinRange = 0.0;

	UPROPERTY(Category = "Attack")
	float AttackMaxRange = 3000.0;
	
	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::XSmall;
	
	UPROPERTY(Category = "Attack")
	int AttackBurstNumber = 3;
	
	UPROPERTY(Category = "Attack")
	float AttackProjectileSpeed = 1000.0;

	UPROPERTY(Category = "Attack")
	float AttackDuration = 1.0;

	UPROPERTY(Category = "Attack")
	float AttackCooldown = 1.0;
	
	UPROPERTY(Category = "Attack")
	float AttackScatterYaw = 1.0;
	
	UPROPERTY(Category = "Attack")
	float AttackScatterPitch = 1.0;


	// When there are others within this range we will move away from them
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceMaxRange = 300.0;

	// Avoid getting this close to anybody as much as possible
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceMinRange = 50.0;

	// Max acceleration away from others
	UPROPERTY(Category = "Combat|CrowdAvoidance")
	float CrowdAvoidanceForce = 50;
	


	UPROPERTY(Category = "Chase")
	float SidescrollerChaseMinRange = 500.0;
	
	UPROPERTY(Category = "Chase")
	float SidescrollerChaseMoveSpeed = 750.0;
	
	UPROPERTY(Category = "Chase")
	float SidescrollerFlyingChaseMinHeight = 500.0;

	// Spacing between slots
	UPROPERTY(Category = "Chase")
	float SidescrollerHeightSlotOffset = 100.0;


	UPROPERTY(Category = "Chase")
	float ChaseMinRange = 500.0;
	
	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 750.0;
	
	UPROPERTY(Category = "Chase")
	float FlyingChaseMinHeight = 300.0;

	// Spacing between slots
	UPROPERTY(Category = "Chase")
	float HeightSlotOffset = 100.0;


	UPROPERTY(Category = "ForceField")
	float ReplenishAmountPerSecond = 0.1;


	UPROPERTY(Category = "Damage")
	float DefaultDamage = 0.2;

	UPROPERTY(Category = "Damage")
	float ForceFieldDefaultDamage = 0.1;

	UPROPERTY(Category = "Damage")
	float HurtReactionDuration = 0.8;
};
