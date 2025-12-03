struct FHazeDevTogglePreset
{
	private FName PresetPath;

	FHazeDevTogglePreset(FName Name, FString Tooltip = "")
	{
#if !RELEASE
		PresetPath = FName(Name);
		DevMenu::AddTogglePreset(PresetPath, Name);
		if (!Tooltip.IsEmpty())
			DevMenu::AddDevToggleTooltip(PresetPath, Tooltip);
#endif
	}

	void Add(const FHazeDevToggleBool& Boolean) const
	{
#if !RELEASE
		DevMenu::AddPresetBooleanToggle(PresetPath, Boolean.TogglePath);
#endif	
	}

	void Add(const FHazeDevToggleBoolPerPlayer& PerPlayerBoolean) const
	{
#if !RELEASE
		DevMenu::AddPresetBooleanToggle(PresetPath, PerPlayerBoolean.MioPath);
		DevMenu::AddPresetBooleanToggle(PresetPath, PerPlayerBoolean.ZoePath);
#endif	
	}

	void Add(const FHazeDevToggleOption& Option) const
	{
#if !RELEASE
		FName OptionLongPath = FName(Option.GroupPath.ToString() + UHazeDevToggleSubsystem::Get().CharOptionDivider + Option.OptionName.ToString());
		DevMenu::AddPresetOptionToggle(PresetPath, OptionLongPath);
#endif
	}
}
