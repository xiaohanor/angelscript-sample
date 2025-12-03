namespace SketchbookBoss
{
	namespace Settings
	{
		//FIGHT
		const float MaxHealth = 100;
		const float DamagePerArrow = 2;

		const float EnterArenaSpeed = 2000;
		

		//Used for calculating arena bounds based on the boss start location
		const float ArenaHalfWidth = 1000;
	}

	const FHazeDevToggleCategory Cheats = FHazeDevToggleCategory(n"Cheats");
	const FHazeDevToggleBool UnkillableBoss = FHazeDevToggleBool(Cheats, n"Unkillable Boss");
}