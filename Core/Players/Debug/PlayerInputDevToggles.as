namespace PlayerInputDevToggles
{
	const FHazeDevToggleCategory PlayerInputCategory = FHazeDevToggleCategory(n"Player Input");

	namespace ButtonMash
	{
		const FHazeDevToggleBoolPerPlayer AutoButtonMash;
	}

	namespace Controller
	{
		const FHazeDevToggleBool SendInputToBothPlayers;
	}
}