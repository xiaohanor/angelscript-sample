class UAudioDebugSplines : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Splines; }
	
	FString GetTitle() override
	{
		return "Splines";
	}
}