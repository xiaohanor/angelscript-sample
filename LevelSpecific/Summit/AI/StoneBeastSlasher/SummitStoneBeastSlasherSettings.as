class USummitStoneBeastSlasherSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Tentacles")
	float IntroGrowthDuration = 6.0;

	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Large;
	
	UPROPERTY(Category = "Attack")
	float AttackPerPlayerCooldown = 2.0;

	UPROPERTY(Category = "Attack")
	float AttackSharedCooldown = 1.0;

	UPROPERTY(Category = "Attack")
	float AttackRange = 700.0;
	
	UPROPERTY(Category = "Attack")
	float AttackDamage = 1.0;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 2.0;

	UPROPERTY(Category = "Attack")
	float AttackAnticipateDuration = 0.5;

	UPROPERTY(Category = "Attack")
	float AttackActionDuration = 1.0;

	UPROPERTY(Category = "Attack")
	float AttackRecoverDuration = 1.5;

	UPROPERTY(Category = "Targeting")
	float TargetingInterval = 1.0;

	UPROPERTY(Category = "Health")
	float DamageFromSword = 0.4;
}