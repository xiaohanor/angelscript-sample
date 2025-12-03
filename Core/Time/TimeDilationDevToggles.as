namespace DevTogglesTimeDilation
{
	const FHazeDevToggleCategory TimeDilationCategory = FHazeDevToggleCategory(n"Time Dilation");
	const FHazeDevToggleGroup ToggledTimeDilation = FHazeDevToggleGroup(TimeDilationCategory, n"TimeDilation");
	const FHazeDevToggleOption Slowest = FHazeDevToggleOption(ToggledTimeDilation, n"0.001");
	const FHazeDevToggleOption Half = FHazeDevToggleOption(ToggledTimeDilation, n"0.5");
	const FHazeDevToggleOption One = FHazeDevToggleOption(ToggledTimeDilation, n"1.0", true);
	const FHazeDevToggleOption Double = FHazeDevToggleOption(ToggledTimeDilation, n"2.0");
	const FHazeDevToggleOption Fastest = FHazeDevToggleOption(ToggledTimeDilation, n"16.0");
}
