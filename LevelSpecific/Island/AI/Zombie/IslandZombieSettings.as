class UIslandZombieSettings : UHazeComposableSettings
{
	// Cost of melee attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "Cooldown")
	float AttackTokenCooldown = 0.5;
}
