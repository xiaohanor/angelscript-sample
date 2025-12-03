class UPlayerVaultSettings : UHazeComposableSettings
{
	// Currently unused min and max height of the vault. Will replace Top Trace Reaches
	const float HeightMin = 80.0;
	const float HeightMax = 150.0;

	const float TopTraceDepth = 12.0;

	// How long it takes the vault to position the capsule on the ledge
	float EnterDurationMin = 0.05;
	float EnterDurationMax = 0.2;
	float EnterDistanceMax = 250.0;

	float ClimbDuration = 0.3;

	// How far the player can vault over something (otherwise they will climb)
	float DistanceMax = 500.0;
	float SlideDistanceMin = 150.0;

	float ExitDuration = 0.1;
}