namespace IslandShieldotronDevToggles
{
	const FHazeDevToggleCategory ShieldotronsCategory = FHazeDevToggleCategory(n"Shieldotrons");
	
	const FHazeDevToggleBool DisableAggressiveTeam = FHazeDevToggleBool(ShieldotronsCategory, n"Teams", n"Disable aggressive team");

	const FHazeDevToggleBool DisableOrbAttack = FHazeDevToggleBool(ShieldotronsCategory, n"Attacks" ,n"Disable Orb Attack");
	const FHazeDevToggleBool DisableMortarAttack = FHazeDevToggleBool(ShieldotronsCategory, n"Attacks" ,n"Disable Mortar Attack");
}	
