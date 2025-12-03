
class UCarChaseTetherPlayerSettings : UHazeComposableSettings
{
	UPROPERTY(Category = TetherSettings)
	float GravityAcceleration = 2400.0;

	UPROPERTY(Category = TetherSettings)
	float InputAcceleration = 800.0;

	UPROPERTY(Category = TetherPointSettings)
	float TetherLength = 1250.0;
}