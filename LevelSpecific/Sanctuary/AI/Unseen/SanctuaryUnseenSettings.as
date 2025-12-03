class USanctuaryUnseenSettings : UHazeComposableSettings
{
	// The minimum speed we slow down to, this is the speed we will be when having reached attack range
	UPROPERTY(Category = "Chase")
	float ChaseAttackSlowdownMinSpeed = 100.0;

	// The range from the point of attack at which we start slowing down
	UPROPERTY(Category = "Chase")
	float ChaseAttackSlowdownRange = 0.0;

	// Interval at which we trigger steps (show fx) while chasing
	UPROPERTY(Category = "Chase")
	float ChaseStepInterval = 0.4;
}