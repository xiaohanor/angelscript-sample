class UAudioDebugGameplay : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Gameplay; }
	
	FString GetTitle() override
	{
		return "Gameplay";
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		
	}
}