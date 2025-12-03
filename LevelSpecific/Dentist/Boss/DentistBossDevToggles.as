namespace DentistBossDevToggles
{
	const FHazeDevToggleCategory DentistBossCategory = FHazeDevToggleCategory(n"DentistBoss");

	const FName Cup = n"Cup";
	const FHazeDevToggleBool InfiniteCupTelegraph = FHazeDevToggleBool(DentistBossCategory, Cup, n"InfiniteCupTelegraph");
	const FHazeDevToggleBool NoCupSorting = FHazeDevToggleBool(DentistBossCategory, Cup, n"NoCupSorting");
	const FHazeDevToggleBool CupPrinting = FHazeDevToggleBool(DentistBossCategory, Cup, n"CupPrinting");

	const FName Dentures = n"Dentures";
	const FHazeDevToggleBool DenturesDontJump = FHazeDevToggleBool(DentistBossCategory, Dentures, n"DenturesDontJump");
}