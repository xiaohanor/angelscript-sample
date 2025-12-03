class UCoastPoltroonSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Attack")
	float AttackMaxRange = 3800;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 2;

	UPROPERTY(Category = "Attack")
	float AttackDuration = 3;

	UPROPERTY(Category = "Attack")
	float AttackRecoverDuration = 1.5;

	UPROPERTY(Category = "Attack")
	float AttackInterval = 1.5;

	UPROPERTY(Category = "Attack")
	float AttackPlayerDamage = 0.01;

	// How quickly we rotate towards our attack target
	UPROPERTY(Category = "Attack")
	float AttackRotationDuration = 0.2;
}
