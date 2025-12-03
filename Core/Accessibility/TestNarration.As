
#if !RELEASE
const FConsoleCommand Command_TestNarration("Haze.TestNarration", n"Narration_TestNarration");
local void Narration_TestNarration(TArray<FString> Arguments)
{
	if (!Game::IsNarrationEnabled())
	{
		devErrorAlways("Narration not enabled!");
		return;
	}

	if (Arguments.Num() > 0)
	{
		FString NarrationText = FString::Join(Arguments, " ").TrimStartAndEnd();
		if (NarrationText.Len() > 0)
		{
			Game::NarrateString(NarrationText);
			return;
		}
	}
	Game::NarrateString("Testing narration text to speech");
}
#endif
