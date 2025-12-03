class UBattlefieldHoverboardWallSettings : UHazeComposableSettings
{
	// The Wall's pitch limits (negative is leaning towards, positive backwards)
	const float WallPitchMinimum = -5.0;
	const float WallPitchMaximum = 10.0;

	// The Top's pitch limits (negative is leaning towards, positive backwards)
	const float TopPitchMinimum = -10.0;
	const float TopPitchMaximum = 10.0;

	const float TopRollMaximum = 30.0;

	// How far we trace for vertical walls (will be adjusted by sphere radius)
	const float WallTraceForwardReach = 100.0;

	// Target units between the player and the wall
	const float TargetDistanceToWall = 75.0;
}