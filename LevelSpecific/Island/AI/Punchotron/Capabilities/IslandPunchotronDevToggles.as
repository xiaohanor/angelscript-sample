namespace IslandPunchotronDevToggles
{
	const FHazeDevToggleCategory PunchotronsCategory = FHazeDevToggleCategory(n"Punchotrons");
	
	const FHazeDevToggleBool EnableForcefieldCutscene = FHazeDevToggleBool(PunchotronsCategory, n"Boss Settings", n"Enable Forcefield Cutscene");
	
	const FHazeDevToggleBool EnableAttackDecals = FHazeDevToggleBool(PunchotronsCategory, n"Attack Settings", n"Enable Attack Decals");
	const FHazeDevToggleBool DisableHaywireAttack = FHazeDevToggleBool(PunchotronsCategory, n"Attack Settings", n"Disable Haywire Attack");
	const FHazeDevToggleBool DisableCobraStrikeAttack = FHazeDevToggleBool(PunchotronsCategory, n"Attack Settings", n"Disable Cobra Strike Attack");
	const FHazeDevToggleBool DisableProximityAttack = FHazeDevToggleBool(PunchotronsCategory, n"Attack Settings", n"Disable Proximity Attack");
	
}	
