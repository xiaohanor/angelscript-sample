class USummitClimbingCritterSettings : UHazeComposableSettings
{
	// Critters stay alive this long before expiring
	UPROPERTY()
	float LifeDuration = 8.0;

	UPROPERTY()
	float ChaseMoveDistance = 200.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Medium;

	UPROPERTY()
	float AttackTokenCooldown = 0.25;

	UPROPERTY()
	float LatchOnAttackRange = 500.0;

	UPROPERTY()
	float LatchOnAttackSpeed = 2000.0;

	UPROPERTY()
	float LatchOnGripRange = 80.0;

	UPROPERTY()
	float LatchOnKillDuration = 5.0;	

	UPROPERTY()
	float LatchOnDamageWarningInterval = 0.5;	

	UPROPERTY()
	float LatchOnMissDuration = 0.8;
}