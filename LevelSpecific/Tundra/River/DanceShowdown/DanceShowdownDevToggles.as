namespace DanceShowdown
{
	const FHazeDevToggleCategory DanceShowdown = FHazeDevToggleCategory(n"DanceShowdown");
	const FName Cheats = n"Cheats";
	const FHazeDevToggleBool NoFail = FHazeDevToggleBool(DanceShowdown, Cheats, n"No fail");
	const FHazeDevToggleBool IgnoreZoeScore = FHazeDevToggleBool(DanceShowdown, Cheats, n"Ignore Zoe Score");
	const FHazeDevToggleBool DontIncreaseScore = FHazeDevToggleBool(DanceShowdown, Cheats, n"Dont increase score");
	const FHazeDevToggleBool SkipTutorial = FHazeDevToggleBool(DanceShowdown, Cheats, n"Skip tutorial");
	const FHazeDevToggleBool AutoShakeMonkey = FHazeDevToggleBool(DanceShowdown, Cheats, n"Auto Shake Monkey");

	const FName Debug = n"Debug";
	const FHazeDevToggleBool DebugPoses = FHazeDevToggleBool(DanceShowdown, Debug, n"Debug Poses");
}