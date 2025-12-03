class UEnforcerGloveSettings : UHazeComposableSettings
{
	// Cost of this attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost GentlemanCost = EGentlemanCost::Small;

	// Minimum distance for using weapon
	UPROPERTY(Category = "Attack")
	float MinimumAttackRange = 350.0;

	// How far ahead should we try to predict the player position when choosing aim position
	UPROPERTY(Category = "Attack")
	float PredictionFactor = 0.5;

	UPROPERTY(Category = "Cooldown")
	float AttackTokenCooldown = 3.0;

	// Wait this long after performing an attack
	UPROPERTY(Category = "Recovery")
	float TelegraphDuration = 0.83;

	UPROPERTY(Category = "Recovery")
	float AttackDuration = 0.5;

	UPROPERTY(Category = "Recovery")
	float RecoveryDuration = 1.33;

	// Player damage
	UPROPERTY(Category = "Projectile")
	float PlayerDamage = 0.2;

	// Player taking damge will also stumble within this distance 
	UPROPERTY(Category = "Projectile")
	float StumbleRange = 2000;
}