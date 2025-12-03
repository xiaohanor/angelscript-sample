class UAudioDebugNodeProperties : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::NodeProperties; }
	
	FString GetTitle() override
	{
		return "NodeProperties";
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
	}
}