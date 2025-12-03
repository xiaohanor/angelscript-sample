namespace IslandPunchotronSidescrollerDevToggles
{
	const FHazeDevToggleCategory SidescrollerPunchotronsCategory = FHazeDevToggleCategory(n"SidescrollerPunchotrons");
	
	const FHazeDevToggleBool DisableHaywireAttack = FHazeDevToggleBool(SidescrollerPunchotronsCategory, n"Attack Settings", n"Disable Haywire Attack");
	const FHazeDevToggleBool DisableCobraStrikeAttack = FHazeDevToggleBool(SidescrollerPunchotronsCategory, n"Attack Settings", n"Disable Cobra Strike Attack");
	const FHazeDevToggleBool DisableKickAttack = FHazeDevToggleBool(SidescrollerPunchotronsCategory, n"Attack Settings", n"Disable Kick Attack");
	const FHazeDevToggleBool DisableJumping = FHazeDevToggleBool(SidescrollerPunchotronsCategory, n"Attack Settings", n"Disable Jumping");
}	
