class UTundra_SimonSaysMonkeyKingSettings : UHazeComposableSettings
{
	UPROPERTY()
	float TurnRate = 20.0;

	UPROPERTY()
	float BezierControlPointHeight = 75.1;

	UPROPERTY()
	float MoveRatioToBeStillFor = 0.2;

	UPROPERTY()
	bool bRotateTowardsDestinationPoint = true;
}