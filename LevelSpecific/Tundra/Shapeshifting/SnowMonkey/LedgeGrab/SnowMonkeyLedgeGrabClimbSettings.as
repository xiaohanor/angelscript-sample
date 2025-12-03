
class USnowMonkeyLedgeGrabClimbSettings : UHazeComposableSettings
{
	// Total duration of Climb Up move
	UPROPERTY()
	float ClimbUpDuration = 0.7;

	// How long the players hands should be planted (Linear movement)
	const float HandPlantDuration = 0.2;

	// How deep into the ledge the climb should aim for
	UPROPERTY()
	float TargetLocationDepth = 80.0;
}