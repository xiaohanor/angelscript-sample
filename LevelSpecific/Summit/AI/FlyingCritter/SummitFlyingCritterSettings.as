class USummitFlyingCritterSettings : UHazeComposableSettings
{
	// Critters stay alive this long before expiring
	UPROPERTY()
	float LifeDuration = 8.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Medium;

	UPROPERTY()
	float AttackTokenCooldown = 0.25;
}