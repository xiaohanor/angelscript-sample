namespace DevTogglesPlayerHealth
{
	const FHazeDevToggleCategory PlayerHealth = FHazeDevToggleCategory(n"Player Health");

	const FHazeDevToggleGroup ZoeGodmodeCategory = FHazeDevToggleGroup(PlayerHealth, n"Godmode Zoe", "More granular godmode");
	const FHazeDevToggleOption ZoeMortal = FHazeDevToggleOption(ZoeGodmodeCategory, n"Mortal", true);
	const FHazeDevToggleOption ZoeGodmode = FHazeDevToggleOption(ZoeGodmodeCategory, n"Godmode");
	const FHazeDevToggleOption ZoeJesusmode = FHazeDevToggleOption(ZoeGodmodeCategory, n"Jesusmode");

	const FHazeDevToggleGroup MioGodmodeCategory = FHazeDevToggleGroup(PlayerHealth, n"Godmode Mio", "More granular godmode");
	const FHazeDevToggleOption MioMortal = FHazeDevToggleOption(MioGodmodeCategory, n"Mortal", true);
	const FHazeDevToggleOption MioGodmode = FHazeDevToggleOption(MioGodmodeCategory, n"Godmode");
	const FHazeDevToggleOption MioJesusmode = FHazeDevToggleOption(MioGodmodeCategory, n"Jesusmode");

	const FHazeDevToggleBool PreventGameOver;

	const FHazeDevToggleBoolPerPlayer DrawRespawnPoint;
}