
class UPlayerFloorSlowdownSettings : UHazeComposableSettings
{
	// Duration of slowdown
	UPROPERTY()
	float Duration = 0.45;

	// Maximum distance that we can slide during the slowdown
	UPROPERTY()
	float MaxSlideDistance = 100.0;

	// The velocity deceleration curve will always have at least this power factor. Increase to stop faster.
	UPROPERTY()
	float MinimumStopPowerCurve = 1.5;
}