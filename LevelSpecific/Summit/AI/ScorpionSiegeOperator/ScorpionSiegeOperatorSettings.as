class UScorpionSiegeOperatorSettings : UHazeComposableSettings
{
	// Gentleman cost of weapon attacks
	UPROPERTY(Category = "Attack|Cost")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "Attack|Cooldown")
	float AttackTokenCooldown = 1.0;
}
