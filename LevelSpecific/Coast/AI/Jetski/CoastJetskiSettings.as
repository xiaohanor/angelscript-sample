class UCoastJetskiSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Engage")
	float EngageDistanceAheadOfPlayer = 4000.0;

	UPROPERTY(Category = "Engage")
	float EngageWithinSplineBuffer = 500.0;

	UPROPERTY(Category = "Engage")
 	float EngageMoveSpeed = 9000.0;

	UPROPERTY(Category = "Engage")
 	float EngageBehindExtraSpeed = 6500.0;


	UPROPERTY(Category = "ObstacleAvoidance")
 	float ObstacleAvoidanceMoveSpeed = 10000.0;

	UPROPERTY(Category = "ObstacleAvoidance")
 	float ObstacleAvoidanceSplineLookahead = 3000.0;

	UPROPERTY(Category = "ObstacleAvoidance")
	float ObstacleAvoidanceProbeRange = 5000.0;

	UPROPERTY(Category = "ObstacleAvoidance")
 	float ObstacleAvoidanceStopDuration = 0.3;


	UPROPERTY(Category = "Attack")
	float AttackRange = 5000;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 0.1;

	UPROPERTY(Category = "Attack")
	float AttackDuration = 3.0;

	UPROPERTY(Category = "Attack")
	float AttackRecoverDuration = 0.7;

	UPROPERTY(Category = "Attack")
	float AttackInterval = 0.2;

	UPROPERTY(Category = "Attack")
	float AttackPlayerDamage = 0.01;


	UPROPERTY(Category = "Deploy")
	bool bDeployEnabled = false;

	UPROPERTY(Category = "Deploy")
	FVector DeployPush = FVector(-500.0, 1000.0, 0.0);

	UPROPERTY(Category = "Deploy")
	float DeployPushDuration = 0.2;

	UPROPERTY(Category = "Deploy")
	float DeployDuration = 2.0;


	UPROPERTY(Category = "Damage")
	float DamageFromProjectilesFactor = 0.2;

	UPROPERTY(Category = "Damage")
	float DamageReactionDuration = 0.4;


	UPROPERTY(Category = "Movement")
	float TurnDuration = 1.0;
	
	UPROPERTY(Category = "Movement")
	float SurfaceFriction = 1.5;

	UPROPERTY(Category = "Movement")
	float AirFriction = 0.1;

	UPROPERTY(Category = "Movement")
	float DiveFriction = 6.0;

	UPROPERTY(Category = "Movement")
	float Gravity = 2000.0;

	UPROPERTY(Category = "Movement")
	float BuoyancyFactor = 1.7;

	UPROPERTY(Category = "Movement")
	float MaxBuoyancy = 6000.0;
}
