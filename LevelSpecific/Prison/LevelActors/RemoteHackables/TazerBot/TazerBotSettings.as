class UTazerBotSettings : UHazeComposableSettings
{
	// Giggity giggity goo!
	UPROPERTY()
	float ShaftLength = 1260.0;

	UPROPERTY(Category = "Movement")
	float MoveSpeed = 600.0;

	UPROPERTY(Category = "Movement")
	float PoleExtendedMoveSpeed = 250.0;

	UPROPERTY(Category = "Movement")
	float MaxTurretRotationSpeed = 2.0;

	UPROPERTY(Category = "Movement")
	float DeployedTurretRotationSpeed = 0.5;

	UPROPERTY(Category = "Movement")
	float CurrentTurretRotationSpeed = MaxTurretRotationSpeed;

	UPROPERTY(Category = "Telescope")
	float ExtendSpeed = 5.0;

	UPROPERTY(Category = "Telescope")
	float RetractSpeed = 10.0;

	UPROPERTY(Category = "Telescope")
	float CollisionInterruptionRetractionMultiplier = 3.4;
}