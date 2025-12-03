class USerpentMovementSettings : UHazeComposableSettings
{
	UPROPERTY()
	float BaseMovementSpeed = 10500.0;

	UPROPERTY()
	float RubberbandMinDistance = 30000.0;

	UPROPERTY()
	float RubberbandMaxDistance = 33000.0;

	UPROPERTY()
	float RubberbandMaxSlow = 0.48;

	UPROPERTY()
	float RubberbandMaxFast = 1.42;

	/** The length of the undulation wave forward
	(0 -> UndulationMagnitude -> 0) */ 
	UPROPERTY(Category = "Undulation")
	FVector UndulationFrequency = FVector(0, 12000, 12000);

	UPROPERTY(Category = "Undulation")
	FVector UndulationMagnitude = FVector(0, 600, 600);
}