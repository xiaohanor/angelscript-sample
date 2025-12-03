/*
	Holds shared settings for wall tracing and limitations
*/

class UPlayerWallSettings : UHazeComposableSettings
{
	// The Wall's pitch limits (negative is leaning towards, positive backwards)
	UPROPERTY()
	float WallPitchMinimum = -5.0;
	UPROPERTY()
	float WallPitchMaximum = 10.0;

	// The Top's pitch limits (negative is leaning towards, positive backwards)
	UPROPERTY()
	float TopPitchMinimum = -10.0;
	UPROPERTY()
	float TopPitchMaximum = 10.0;

	UPROPERTY()
	float TopRollMaximum = 30.0;

	// How far we trace for vertical walls (will be adjusted by sphere radius)
	UPROPERTY()
	float WallTraceForwardReach = 80.0;

	// Target units between the player and the wall
	UPROPERTY()
	float TargetDistanceToWall = 56.0;
}