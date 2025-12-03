namespace AviationDevToggles
{
	const FHazeDevToggleCategory Aviation = FHazeDevToggleCategory(n"Aviation");

	const FHazeDevToggleGroup MovementMode = FHazeDevToggleGroup(Aviation, n"Movement Mode", "Used type of movement while aviating");
	const FHazeDevToggleOption FreeAbsolute = FHazeDevToggleOption(MovementMode, n"Free Absolute", true);
	const FHazeDevToggleOption FreeDelta = FHazeDevToggleOption(MovementMode, n"Free Delta");
	const FHazeDevToggleOption FreeStrafeOnly = FHazeDevToggleOption(MovementMode, n"Free Strafe Only");
	const FHazeDevToggleOption StrafeArcadey = FHazeDevToggleOption(MovementMode, n"Strafe Arcadey");
	// const FHazeDevToggleOption StrafeLerpedSpeeds = FHazeDevToggleOption(MovementMode, n"Strafe Lerped Speeds");

	const FHazeDevToggleBool DrawPath;

	namespace Camera
	{
		const FHazeDevToggleBool NoCameraOffset;
		const FHazeDevToggleBool UseStaticCameraSwoopBack;
		const FHazeDevToggleBool DrawCameraFocus;
	}

	namespace Tutorial
	{
		const FHazeDevToggleBool TutorialIgnoreEssence;
	}
	
	namespace Phase1
	{
		const FHazeDevToggleBool Phase1IgnoreEssence;
		const FHazeDevToggleBool Phase1AutoInitateAttack;
		const FHazeDevToggleBool AutoPromptRiding;
		const FHazeDevToggleBool Phase1DrawArenaSlices;
		const FHazeDevToggleBool Phase1PrintKillValues;
		const FHazeDevToggleBool Phase1SlowerAttack;
	}
};