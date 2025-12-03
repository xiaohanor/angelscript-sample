class USummitBallFlyerSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Attack")
	float AttackMaxRange = 5000.0;

	UPROPERTY(Category = "Attack")
	float AttackMinRange = 2000.0;

	UPROPERTY(Category = "Attack")
	float AttackMinAngle = 30.0;

	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 2.0;

	// All projectiles used in attack is spawned during this interval, then launched after telegraph duration
	UPROPERTY(Category = "Attack")
	float AttackDeployDuration = 0.5;

	UPROPERTY(Category = "Attack")
	float AttackDeployDistance = 100.0;

	// How many projectiles to spawn
	UPROPERTY(Category = "Attack")
	int AttackNumber = 2;

	UPROPERTY(Category = "Attack")
	float AttackYawWidth = 90.0;

	UPROPERTY(Category = "Attack")
	float AttackScatterPitch = 5.0;

	UPROPERTY(Category = "Attack")
	float AttackCooldown = 5.0;

	UPROPERTY(Category = "Attack")
	float AttackProjectileFlightDuration = 2.0;

	UPROPERTY(Category = "Attack")
	float AttackProjectileExplodeRadius = 200.0; 

	UPROPERTY(Category = "Attack")
	float AttackProjectileDamageRadius = 600.0;

	UPROPERTY(Category = "Attack")
	float AttackProjectileDamageCooldown = 1.0;

	UPROPERTY(Category = "Attack")
	float AttackProjectileDamage = 0.5;

	
	UPROPERTY(Category = "Holding")
	float HoldingSpeed = 2000.0;

	UPROPERTY(Category = "Holding")
	float HoldingRadius = 2000.0;


	UPROPERTY(Category = "HurtRecoil")
	float HurtRecoilDamageFactor = 1.0;

	UPROPERTY(Category = "HurtRecoil")
	float HurtRecoilDuration = 3.0;

	UPROPERTY(Category = "HurtRecoil")
	float HurtRecoilSpeed = 5000.0;

	UPROPERTY(Category = "HurtRecoil")
	float HurtRecoilRange = 3000.0;

	UPROPERTY(Category = "HurtRecoil")
	float HurtRecoilCooldown = 2.0;

	
	UPROPERTY(Category = "Chase")
	float ChaseSpeed = 4000.0;

	UPROPERTY(Category = "Chase")
	float ChaseRange = 10000.0;

	UPROPERTY(Category = "Chase")
	FVector ChaseFlankingOffset = FVector(3500.0, 600.0, 100.0);

	UPROPERTY(Category = "Chase")
	float ChaseMinDuration = 5.0;


	UPROPERTY(Category = "GuardSpline")
	float GuardSplineRange = 20000.0;

	UPROPERTY(Category = "GuardSpline")
	FVector GuardSplineOffset = FVector(0.0, 0.0, 1000.0);

	UPROPERTY(Category = "GuardSpline")
	float GuardSplineMinRange = 5000.0;

	UPROPERTY(Category = "GuardSpline")
	float GuardSplineMinRangeCooldown = 2.0;

	UPROPERTY(Category = "GuardSpline")
	float GuardSplineMoveSpeed = 4000.0;

	UPROPERTY(Category = "GuardSpline")
	float GuardSplineAtSplineDistance = 2000.0;
}
