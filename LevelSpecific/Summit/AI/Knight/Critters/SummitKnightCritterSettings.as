class USummitKnightCritterSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 1200.0;

	UPROPERTY(Category = "Chase")
	float ChaseMinRange = 400.0;

	UPROPERTY(Category = "Chase")
	float ChaseMinRangeCooldown = 0.5;


	UPROPERTY(Category = "LatchOn")
	float LatchOnAttackRange = 800.0;

	UPROPERTY(Category = "LatchOn")
	float LatchOnAttackSpeed = 1200.0;

	UPROPERTY(Category = "LatchOn")
	float LatchOnDamagePerSecond = 0.01;

	UPROPERTY(Category = "LatchOn")
	float LatchOnKillDuration = -1.0;
}