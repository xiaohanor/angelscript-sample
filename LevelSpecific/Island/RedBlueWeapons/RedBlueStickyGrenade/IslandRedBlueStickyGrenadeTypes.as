namespace IslandRedBlueStickyGrenade
{
	const FName IslandRedBlueStickyGrenade = n"IslandRedBlueStickyGrenade";

	const FHazeDevToggleCategory Category = FHazeDevToggleCategory(n"IslandRedBlueStickyGrenade");
	const FHazeDevToggleBool AutoThrow = FHazeDevToggleBool(Category, n"Auto Throw Grenade", "If true the grenade will automatically be thrown as soon as it is possible for it to be thrown");
	const FHazeDevToggleBool AutoDetonate = FHazeDevToggleBool(Category, n"Auto Detonate Grenade", "If true the grenade will automatically detonate as soon as it is possible for it to be thrown");
	const FHazeDevToggleBool MendForceFieldsOnThrow = FHazeDevToggleBool(Category, n"Mend Force Field Holes On Throw", "If true all force field holes will be reset when a grenade is thrown");
}