class UAudioDebugPerformance : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Performance; }
	
	FString GetTitle() override
	{
		return "Performance";
	}

	// They slow down the game quite a lot, so only enable it when really needed.
	bool bRegisteredWithCallback = false;

	int LastNumOfObjects = 0;

	void RegisterToCallbacks()
	{
		if (bRegisteredWithCallback)
			return;

		AudioUtility::RegisterOnOutputDeviceMetering();
		AudioUtility::RegisterResourceMonitoring();

		bRegisteredWithCallback = true;
	}

	void Setup(UAudioDebugManager DebugManager) override
	{
		Super::Setup(DebugManager);
		
		// Resets on end pie
		if (AudioDebug::IsEnabled(EHazeAudioDebugType::Performance))
		{
			RegisterToCallbacks();
		}
		else 
		{
			bRegisteredWithCallback = false;
		}
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		Super::Draw(DebugManager, Section);

		RegisterToCallbacks();
		
		auto ProfilingData = AudioUtility::GetProfilingData();
		// This creates a global lock, only use when needed.
		if (LastNumOfObjects == 0 && ProfilingData.NumSystemAudioObjects > 0)
		{
			int MaxNumberOfAudioObjects = AudioUtility::GetMaxNumAudioObjects();
			LastNumOfObjects = MaxNumberOfAudioObjects;
		}
		else if (ProfilingData.NumSystemAudioObjects == 0)
		{
			LastNumOfObjects = 0;
		}

		Section
			.SlotPadding(20, 0)
			.Text(f"AudioObjects Active: {ProfilingData.NumSystemAudioObjects} of {LastNumOfObjects}")
			.Bold()
			.Color(FLinearColor::LucBlue);

		Section
			.SlotPadding(20, 0)
			.Text(f"TotalCPU: {ProfilingData.TotalCPU}")
			.Color(FLinearColor::LucBlue);

		Section
			.SlotPadding(20, 0)
			.Text(f"PluginCPU: {ProfilingData.PluginCPU}")
			.Color(FLinearColor::LucBlue);
		
		Section
			.SlotPadding(20, 0)
			.Text(f"PhysicalVoices: {ProfilingData.PhysicalVoices}")
			.Color(FLinearColor::LucBlue);

		Section
			.SlotPadding(20, 0)
			.Text(f"VirtualVoices: {ProfilingData.VirtualVoices}")
			.Color(FLinearColor::LucBlue);

		Section
			.SlotPadding(20, 0)
			.Text(f"TotalVoices: {ProfilingData.TotalVoices}")
			.Color(FLinearColor::LucBlue);

		Section
			.SlotPadding(20, 0)
			.Text(f"NumberOfActiveEvents: {ProfilingData.NumberOfActiveEvents}")
			.Color(FLinearColor::LucBlue);

	}
}