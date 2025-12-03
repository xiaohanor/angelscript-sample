class UCoastContainerTurretSettings : UHazeComposableSettings
{
	// Duration of sliding out of container
	UPROPERTY(Category = "Slide Out")
	float SlideOutDuration = 1;

	// Distance that weapon slides out of container
	UPROPERTY(Category = "Slide Out")
	float SlideOutDistance = 300;

	// Cooldown duration before the weapons tries sliding out again
	UPROPERTY(Category = "Slide Out")
	float SlideOutCooldown = 5;

	// Duration of sliding back into container
	UPROPERTY(Category = "Slide In")
	float SlideInDuration = 1;

	UPROPERTY(Category = "Attack")
	float AttackMaxRange = 2800;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 2;

	UPROPERTY(Category = "Attack")
	float AttackDuration = 1.5;

	UPROPERTY(Category = "Attack")
	float AttackRecoverDuration = 1.5;

	UPROPERTY(Category = "Attack")
	float AttackInterval = 0.1;

	UPROPERTY(Category = "Attack")
	float AttackPlayerDamage = 0.075;

	// How quickly we rotate towards our attack target
	UPROPERTY(Category = "Attack")
	float AttackRotationDuration = 0.2;

	// Max at this distance from an attack that impacts a wall, the player will get a camera shake
	UPROPERTY(Category = "Attack")
	float AttackWallImpactCameraShakeDistance = 500;

	UPROPERTY(Category = "Damage")
	float DamageFactor = 0.02;
}
