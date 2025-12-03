
class USnowMonkeyLedgeGrabEnterDropSettings : UHazeComposableSettings
{
	// How far we trace to find a ledge grab position from the players location
	UPROPERTY()
	float StationaryDropDistance = 80.0;

	// How many trace steps the stationary trace will do to test around the player
	const int StationaryTraceSteps = 6;
	// The angle difference of each step
	const float StationaryStepAngle = 60.0;
	const float StationaryTraceHeightFromPlayer = -50.0;
}