namespace SkylineInnerReceptionistDevToggles
{
	const FHazeDevToggleCategory ReceptionistCatergory = FHazeDevToggleCategory(n"Skyline Inner Receptionist");
	const FHazeDevToggleGroup Expression = FHazeDevToggleGroup(ReceptionistCatergory, n"Override Idle Expression");
	const FHazeDevToggleOption None = FHazeDevToggleOption(Expression, n"None", true);
	const FHazeDevToggleOption Normal = FHazeDevToggleOption(Expression, n"Normal");
	const FHazeDevToggleOption Worried = FHazeDevToggleOption(Expression, n"Worried");
	const FHazeDevToggleOption Hello = FHazeDevToggleOption(Expression, n"Hello");
	const FHazeDevToggleOption Cat = FHazeDevToggleOption(Expression, n"Cat");
	const FHazeDevToggleOption Smirk = FHazeDevToggleOption(Expression, n"Smirk");
	const FHazeDevToggleOption Sunglasses = FHazeDevToggleOption(Expression, n"Sunglasses");
	const FHazeDevToggleOption Smile = FHazeDevToggleOption(Expression, n"Smile");
	const FHazeDevToggleOption UvU = FHazeDevToggleOption(Expression, n"UvU");
}
