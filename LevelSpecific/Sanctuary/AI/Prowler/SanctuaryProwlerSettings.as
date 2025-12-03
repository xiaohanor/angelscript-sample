class USanctuaryProwlerSettings : UHazeComposableSettings
{
	UPROPERTY()
	float AttackRange = 600.0;

	UPROPERTY()
	float AttackMaxAngleDegrees = 5.0;

	UPROPERTY()
	float AttackCooldown = 0.0;

	UPROPERTY()
	float AttackTokenCooldown = 2.0;

	UPROPERTY()
	float AttackTelegraphDuration = 0.8;
	UPROPERTY()
	float AttackAnticipationDuration = 1.0;
	UPROPERTY()
	float AttackHitDuration = 0.5;
	UPROPERTY()
	float AttackRecoveryDuration = 2.5;

	UPROPERTY()
	float AttackRadius = 250.0;

	UPROPERTY()
	float AttackInnerRadius = 250.0;

	UPROPERTY()
	float AttackDamage = 1.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost GentlemanCost = EGentlemanCost::Medium;
};

