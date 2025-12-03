namespace CoastBossDevToggles
{
	const FHazeDevToggleCategory CoastBoss = FHazeDevToggleCategory(n"Coast Boss");
	
	const FHazeDevToggleBool KillAnyDrones;
	const FHazeDevToggleBool UseManyDrones;
	const FHazeDevToggleBool AutoShoot;
	const FHazeDevToggleBool BarragePlayerPowerUp;
	const FHazeDevToggleBool LaserPlayerPowerUp;
	const FHazeDevToggleBool HomingPlayerPowerUp;
	const FHazeDevToggleBool DisablePowerUpSpawns;
	const FHazeDevToggleBool PlayersInvulnerable;
	const FHazeDevToggleBool AutoKillDrones;

	namespace Draw
	{
		const FHazeDevToggleBool Draw2DPlane;
		const FHazeDevToggleBool DrawDebugPlayers;
		const FHazeDevToggleBool DrawDebugCollisions;
		const FHazeDevToggleBool DrawDebugTrain;
		const FHazeDevToggleBool DrawDebugBoss;
		const FHazeDevToggleBool DrawDebugTimer;
	}

	const FHazeDevToggleGroup ForcePhase = FHazeDevToggleGroup(CoastBoss, n"Force Phase");
	const FHazeDevToggleOption PhaseNone = FHazeDevToggleOption(ForcePhase, n"None");
	const FHazeDevToggleOption Phase24 = FHazeDevToggleOption(ForcePhase, n"24 STAR");
	const FHazeDevToggleOption Phase20 = FHazeDevToggleOption(ForcePhase, n"20 CROSS");
	const FHazeDevToggleOption Phase16 = FHazeDevToggleOption(ForcePhase, n"16 WEATHER");
	const FHazeDevToggleOption Phase12 = FHazeDevToggleOption(ForcePhase, n"12 DRILLBAZZ");
	const FHazeDevToggleOption Phase8 = FHazeDevToggleOption(ForcePhase, n" 8 BANANA");
	const FHazeDevToggleOption Phase4 = FHazeDevToggleOption(ForcePhase, n" 4 PINGPONG");

}