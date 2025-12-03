class UTeenDragonRollRailSettings : UHazeComposableSettings
{
	/* Minimum speed allowed inside the rail */
	UPROPERTY(Category = "Speed")
	float MinSpeed = 2000.0;

	/* Max speed allowed inside the rail */
	UPROPERTY(Category = "Speed")
	float MaxSpeed = 7000.0;

	UPROPERTY(Category = "Speed")
	float GravityUpSlopeMultiplier = 0.5;

	UPROPERTY(Category = "Speed")
	float GravityDownSlopeMultiplier = 1.0;

}